defmodule Protohackers.MITM.Acceptor do
  use Task
  require Logger

  def start_link([]) do
    Logger.debug("Starting acceptor")
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    case :gen_tcp.listen(5006, [
           :binary,
           active: true,
           reuseaddr: true,
           packet: :line,
           buffer: 100 * 1024
         ]) do
      {:ok, socket} ->
        Logger.info("Starting MITM acceptor on port 5006")
        accept(socket)

      {:error, reason} ->
        raise "Failed to start MITM acceptor: #{inspect(reason)}"
    end
  end

  defp accept(listen_socket) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, socket} ->
        with {:ok, conn} <- Protohackers.MITM.ConnectionSup.start_child(socket),
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
