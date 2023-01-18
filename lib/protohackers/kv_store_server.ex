defmodule Protohackers.KvStoreServer do
  use GenServer
  require Logger

  def start_link([]) do
    GenServer.start_link(__MODULE__, :empty, [])
  end

  defstruct [:socket, store: %{"version" => "kvstore1.0"}]

  @impl true
  def init(:empty) do
    # if we test using 'nc' and 'localhost', nc will default to inet6
    # set it to 'inet6', we can still access it using inet4
    case :gen_udp.open(5005, [:binary, :inet6, active: false, recbuf: 1000]) do
      {:ok, socket} ->
        Logger.info("Starting kv store server")
        state = %__MODULE__{socket: socket}
        {:ok, state, {:continue, :recv}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:recv, state = %__MODULE__{}) do
    case :gen_udp.recv(state.socket, 0) do
      {:ok, {address, port, packet}} ->
        Logger.debug("Received UDP packet #{inspect(packet)}")

        state =
          case String.split(packet, "=", parts: 2) do
            # ignore setting "version" key
            ["version", _] ->
              state

            [key, value] ->
              Logger.debug("Insert key #{inspect(key)} with value #{inspect(value)}")
              put_in(state.store[key], value)

            [key] ->
              Logger.debug("Query key #{inspect(key)}")
              :gen_udp.send(state.socket, address, port, "#{key}=#{state.store[key]}")
              state
          end

        {:noreply, state, {:continue, :recv}}

      {:error, reason} ->
        Logger.debug("stop, #{inspect(reason)}")
        {:stop, reason}
    end
  end
end
