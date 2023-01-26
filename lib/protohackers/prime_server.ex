defmodule Protohackers.PrimeServer do
  use GenServer
  require Logger

  defstruct [:listen_socket, :supervisor]

  def start_link([]) do
    GenServer.start_link(__MODULE__, :empty, [])
  end

  @impl true
  def init(:empty) do
    {:ok, supervisor} = Task.Supervisor.start_link(max_children: 100)

    listen_opts = [
      mode: :binary,
      active: false,
      reuseaddr: true,
      exit_on_close: false,
      # lines longer than the receive buffer are truncated
      packet: :line,
      buffer: 100 * 1024
    ]

    case :gen_tcp.listen(5002, listen_opts) do
      {:ok, socket} ->
        Logger.info("Starting prime server on port 5002")
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
    case handle_lines_until_closed(socket) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to handle connection: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end

  defp handle_lines_until_closed(socket) do
    case :gen_tcp.recv(socket, 0, 10_0000) do
      {:ok, data} ->
        case Jason.decode(data) do
          {:ok, _json = %{"method" => "isPrime", "number" => number}} when is_number(number) ->
            Logger.debug("Received valid request for number #{inspect(number)}")

            :gen_tcp.send(socket, [
              Jason.encode!(%{"method" => "isPrime", "prime" => prime?(number)}),
              ?\n
            ])

            handle_lines_until_closed(socket)

          other ->
            Logger.debug("Received invalid request: #{inspect(other)}")
            :gen_tcp.send(socket, "malformed request\n")
            {:error, :invalid_request}
        end

      {:error, :closed} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp prime?(number) when is_float(number), do: false
  defp prime?(number) when number <= 1, do: false
  defp prime?(number) when number in [2, 3], do: true

  defp prime?(number) do
    not Enum.any?(2..trunc(:math.sqrt(number)), &(rem(number, &1) == 0))
  end
end
