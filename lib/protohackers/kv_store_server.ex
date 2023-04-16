defmodule Protohackers.KvStoreServer do
  use GenServer
  require Logger

  def start_link([]) do
    GenServer.start_link(__MODULE__, :empty, [])
  end

  defstruct [:socket, store: %{"version" => "kvstore1.0"}]

  @impl true
  def init(:empty) do
    address =
      case System.fetch_env("FLY_APP_NAME") do
        {:ok, _} ->
          {:ok, fly_global_ip} = :inet.getaddr(~c"fly-global-services", :inet)
          fly_global_ip

        :error ->
          {0, 0, 0, 0}
      end

    # NOTE: make sure to use 'nc -4' to test this server
    case :gen_udp.open(8888, [:binary, active: false, recbuf: 1000, ip: address]) do
      {:ok, socket} ->
        Logger.info("Starting kv store server on #{:inet.ntoa(address)}:8888")
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
        Logger.debug(
          "Received UDP packet from #{inspect(address)}:#{inspect(port)} #{inspect(packet)}"
        )

        state =
          case String.split(packet, "=", parts: 2) do
            # ignore setting "version" key
            ["version", _] ->
              state

            [key, value] ->
              Logger.debug("Insert key #{inspect(key)} with value #{inspect(value)}")
              put_in(state.store[key], value)

            [key] ->
              value = state.store[key]
              Logger.debug("Query key #{inspect(key)}, will reply with value #{inspect(value)}")
              :gen_udp.send(state.socket, address, port, "#{key}=#{value}")
              state
          end

        {:noreply, state, {:continue, :recv}}

      {:error, reason} ->
        Logger.debug("stop, #{inspect(reason)}")
        {:stop, reason}
    end
  end
end
