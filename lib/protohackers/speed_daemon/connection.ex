defmodule Protohackers.SpeedDaemon.Connection do
  use GenServer, restart: :temporary
  require Logger
  alias Protohackers.SpeedDaemon.{Message, Processor, DispatcherRegistry}

  # for type = :camera, extra = {road, mile, limit}
  # for type = :dispatcher, extra = nil
  defstruct [:socket, :type, :extra, :heartbeat_ref, buffer: <<>>]

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  @impl true
  def init(socket) do
    Logger.debug("Starting connection handler")
    {:ok, %__MODULE__{socket: socket}}
  end

  @impl true
  def handle_cast(
        {:send_ticket, %Message.Ticket{} = ticket},
        %__MODULE__{type: :dispatcher} = state
      ) do
    send_message(state.socket, ticket)
    {:noreply, state}
  end

  # client message
  @impl true
  def handle_info(message, state)

  def handle_info({:tcp, socket, data}, %__MODULE__{socket: socket} = state) do
    :ok = :inet.setopts(socket, active: :once)
    state = update_in(state.buffer, &(&1 <> data))
    parse_all_messages(state)
  end

  def handle_info({:tcp_closed, socket}, %__MODULE__{socket: socket} = state) do
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, socket, reason}, %__MODULE__{socket: socket} = state) do
    Logger.error("Received tcp error: #{inspect(reason)}")
    {:stop, :normal, state}
  end

  def handle_info(:send_heartbeat, %__MODULE__{} = state) do
    send_message(state.socket, %Message.Heartbeat{})
    {:noreply, state}
  end

  ## Private

  defp handle_message(msg, state)

  defp handle_message(%Message.IAmCamera{road: road, mile: mile, limit: limit}, state) do
    if state.type == nil do
      Logger.metadata(type: :camera, road: road, mile: mile, limit: limit)
      Processor.add_road(road, limit)
      {:ok, %__MODULE__{state | type: :camera, extra: {road, mile, limit}}}
    else
      {:error, "Already identified as camera or dispatcher"}
    end
  end

  defp handle_message(%Message.IAmDispatcher{roads: roads}, state) do
    if state.type == nil do
      for road <- roads do
        {:ok, _} = Registry.register(DispatcherRegistry, road, :unused)
      end

      Logger.metadata(type: :dispatcher)

      {:ok, %__MODULE__{state | type: :dispatcher}}
    else
      {:error, "Already identified as camera or dispatcher"}
    end
  end

  defp handle_message(%Message.Plate{plate: plate, timestamp: timestamp}, state) do
    if state.type != :camera do
      {:error, "plate message received while it's not a camera"}
    else
      {road, mile, _} = state.extra

      Processor.add_record(road, plate, mile, timestamp)

      {:ok, state}
    end
  end

  defp handle_message(%Message.WantHeartbeat{interval: interval}, state) do
    if state.heartbeat_ref do
      {:error, "WantHeartbeat already received"}
    else
      interval_in_ms = interval * 100

      if interval_in_ms > 0 do
        {:ok, heartbeat_ref} = :timer.send_interval(interval_in_ms, :send_heartbeat)
        {:ok, %__MODULE__{state | heartbeat_ref: heartbeat_ref}}
      else
        {:ok, state}
      end
    end
  end

  defp send_error_and_close(socket, reason) do
    Logger.error("error #{inspect(reason)}")
    :gen_tcp.send(socket, Message.encode(%Message.Error{msg: reason}))
    :gen_tcp.close(socket)
  end

  defp send_message(socket, msg) do
    :gen_tcp.send(socket, Message.encode(msg))
  end

  defp parse_all_messages(state) do
    case Message.decode(state.buffer) do
      {:ok, msg, rest} ->
        Logger.debug("Message received: #{inspect(msg)}")
        state = put_in(state.buffer, rest)

        case handle_message(msg, state) do
          {:ok, state} ->
            parse_all_messages(state)

          {:error, reason} ->
            send_error_and_close(state.socket, reason)
            {:stop, :normal, reason}
        end

      :incomplete ->
        {:noreply, state}

      :error ->
        send_error_and_close(state.socket, "invalid message type")
        {:stop, :normal, state}
    end
  end
end
