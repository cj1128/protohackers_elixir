defmodule Protohackers.SpeedDaemon.Acceptor do
  use Task, restart: :transient
  require Logger

  def start_link([]) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    case :gen_tcp.listen(8888, [
           :binary,
           active: :once,
           reuseaddr: true
         ]) do
      {:ok, socket} ->
        Logger.info("Starting SpeedDaemon acceptor on port 8888")
        accept(socket)

      {:error, reason} ->
        raise "Failed to start SpeedDaemon acceptor: #{inspect(reason)}"
    end
  end

  defp accept(listen_socket) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, socket} ->
        with {:ok, conn} <- Protohackers.SpeedDaemon.ConnectionSup.start_child(socket),
             :ok <- :gen_tcp.controlling_process(socket, conn) do
          accept(listen_socket)
        else
          err ->
            raise "Failed to handle connection: #{inspect(err)}"
        end

      {:error, reason} ->
        raise "Failed to accept connection: #{inspect(reason)}"
    end
  end
end
