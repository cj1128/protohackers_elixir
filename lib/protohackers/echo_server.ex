defmodule Protohackers.EchoServer do
  use GenServer
  require Logger

  defstruct [:listen_socket, :supervisor]

  def start_link([]) do
    GenServer.start_link(__MODULE__, :empty, [])
  end

  @impl true
  def init(:empty) do
    {:ok, supervisor} = Task.Supervisor.start_link(max_children: 100)

    listen_opts = [mode: :binary, active: false, reuseaddr: true, exit_on_close: false]

    case :gen_tcp.listen(5001, listen_opts) do
      {:ok, socket} ->
        Logger.info("Starting echo server")
        state = %__MODULE__{listen_socket: socket, supervisor: supervisor}
        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, state = %__MODULE__{}) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        Task.Supervisor.start_child(state.supervisor, fn -> handle_connection(socket) end)
        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  defp handle_connection(socket) do
    case recv_until_closed(socket, _buffer = "", _buffer_size = 0) do
      {:ok, data} ->
        :gen_tcp.send(socket, data)

      {:error, reason} ->
        Logger.error("Failed to receive data: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end

  @limit _100kb = 100 * 1024

  defp recv_until_closed(socket, buffer, buffer_size) do
    case :gen_tcp.recv(socket, 0, 100_000) do
      {:ok, data} when buffer_size + byte_size(data) > @limit ->
        {:error, :buffer_overflow}

      {:ok, data} ->
        recv_until_closed(socket, [buffer, data], buffer_size + byte_size(data))

      {:error, :closed} ->
        {:ok, buffer}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
