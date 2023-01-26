defmodule Protohackers.BudgetChatServer do
  use GenServer
  require Logger

  defstruct [:listen_socket, :supervisor, :ets]

  def start_link([]) do
    GenServer.start_link(__MODULE__, :empty, [])
  end

  @impl true
  def init(:empty) do
    {:ok, supervisor} = Task.Supervisor.start_link(max_children: 100)

    ets = :ets.new(__MODULE__, [:public])

    listen_opts = [
      mode: :binary,
      active: false,
      reuseaddr: true,
      exit_on_close: false,
      # lines longer than the receive buffer are truncated
      packet: :line,
      buffer: 100 * 1024
    ]

    case :gen_tcp.listen(5004, listen_opts) do
      {:ok, socket} ->
        Logger.info("Starting budget chat server on port 5004")
        state = %__MODULE__{listen_socket: socket, supervisor: supervisor, ets: ets}
        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, state = %__MODULE__{}) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        Task.Supervisor.start_child(state.supervisor, fn ->
          handle_connection(socket, state.ets)
        end)

        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  defp handle_connection(socket, ets) do
    :ok = :gen_tcp.send(socket, "Welcome to budgetchat! What's your name?\n")

    case :gen_tcp.recv(socket, 0, 300_000) do
      {:ok, line} ->
        username = String.trim(line)

        if username =~ ~r/^[[:alnum:]]+$/ do
          Logger.debug("User #{username} joined")
          all_users = :ets.match(ets, :"$1")
          usernames = Enum.map(all_users, fn [{_socket, username}] -> username end)
          sockets = Enum.map(all_users, fn [{socket, _username}] -> socket end)

          sockets
          |> Enum.each(fn socket ->
            :gen_tcp.send(socket, "* #{username} has joined the room\n")
          end)

          :ets.insert(ets, {socket, username})
          :ok = :gen_tcp.send(socket, "* The room contains: #{Enum.join(usernames, ", ")}\n")

          handle_chat_session(socket, ets, username)
        else
          :ok = :gen_tcp.send(socket, "Invalid username\n")
          :gen_tcp.close(socket)
        end

      {:error, _} ->
        :gen_tcp.close(socket)
        :ok
    end
  end

  def handle_chat_session(socket, ets, username) do
    case :gen_tcp.recv(socket, 0, 300_000) do
      {:ok, line} ->
        msg = String.trim(line)
        sockets = :ets.match(ets, {:"$1", :_})

        for [other_socket] <- sockets, other_socket != socket do
          :gen_tcp.send(other_socket, "[#{username}] #{msg}\n")
        end

        handle_chat_session(socket, ets, username)

      {:error, _reason} ->
        sockets = :ets.match(ets, {:"$1", :_})

        for [other_socket] <- sockets, other_socket != socket do
          :gen_tcp.send(other_socket, "* #{username} has left the room\n")
          :gen_tcp.close(socket)
          :ets.delete(ets, socket)
        end
    end
  end
end
