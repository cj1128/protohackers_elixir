defmodule Protohackers.PriceServer do
  use GenServer
  require Logger
  alias Protohackers.PriceServer.DB

  defstruct [:listen_socket, :supervisor]

  def start_link([]) do
    GenServer.start_link(__MODULE__, :empty, [])
  end

  @impl true
  def init(:empty) do
    {:ok, supervisor} = Task.Supervisor.start_link(max_children: 100)

    listen_opts = [mode: :binary, active: false, reuseaddr: true, exit_on_close: false]

    case :gen_tcp.listen(5003, listen_opts) do
      {:ok, socket} ->
        Logger.info("Starting price server")
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
    case handle_client(socket, DB.new()) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to receive data: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end

  defp handle_client(socket, db) do
    case :gen_tcp.recv(socket, 9, 10_000) do
      {:ok, data} ->
        case handle_request(db, data) do
          {nil, db} ->
            handle_client(socket, db)

          {response, db} ->
            :gen_tcp.send(socket, response)
            handle_client(socket, db)

          :error ->
            {:error, :invalid_request}
        end

      {:error, :timeout} ->
        handle_client(socket, db)

      {:error, :closed} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  def handle_request(db, <<?I, timestamp::32-signed-big, price::32-signed-big>>) do
    {nil, DB.add(db, timestamp, price)}
  end

  def handle_request(db, <<?Q, mintime::32-signed-big, maxtime::32-signed-big>>) do
    res = DB.query(db, mintime, maxtime)
    {<<res::32-signed-big>>, db}
  end

  def handle_request(_, _) do
    :error
  end
end
