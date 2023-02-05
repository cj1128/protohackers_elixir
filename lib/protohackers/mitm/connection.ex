defmodule Protohackers.MITM.Connection do
  use GenServer, restart: :temporary
  require Logger
  alias Protohackers.MITM.Boguscoin

  defstruct [:incoming_socket, :outgoing_socket]

  def start_link(incoming_socket) do
    GenServer.start_link(__MODULE__, incoming_socket)
  end

  def init(incoming_socket) do
    case :gen_tcp.connect(~c"chat.protohackers.com", 16963, [
           :binary,
           active: true,
           packet: :line,
           buffer: 100 * 1024
         ]) do
      {:ok, outgoing_socket} ->
        Logger.debug("Starting connection handler")
        {:ok, %__MODULE__{incoming_socket: incoming_socket, outgoing_socket: outgoing_socket}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  # client message
  def handle_info({:tcp, socket, data}, %__MODULE__{incoming_socket: socket} = state) do
    Logger.debug("Received client data: #{inspect(data)}")
    :gen_tcp.send(state.outgoing_socket, Boguscoin.rewrite(data))
    {:noreply, state}
  end

  # server message
  def handle_info({:tcp, socket, data}, %__MODULE__{outgoing_socket: socket} = state) do
    Logger.debug("Received server data: #{inspect(data)}")
    :gen_tcp.send(state.incoming_socket, Boguscoin.rewrite(data))
    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, %__MODULE__{} = state)
      when socket in [state.incoming_socket, state.outgoing_socket] do
    :gen_tcp.close(state.incoming_socket)
    :gen_tcp.close(state.outgoing_socket)
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, socket, reason}, %__MODULE__{} = state)
      when socket in [state.incoming_socket, state.outgoing_socket] do
    Logger.error("Received tcp error: #{inspect(reason)}")
    :gen_tcp.close(state.incoming_socket)
    :gen_tcp.close(state.outgoing_socket)
    {:stop, :normal, state}
  end
end
