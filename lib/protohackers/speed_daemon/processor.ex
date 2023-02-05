defmodule Protohackers.SpeedDaemon.Processor do
  use GenServer
  require Logger
  alias Protohackers.SpeedDaemon.{Util, DispatcherRegistry}

  # limits: road -> limit
  # records: {road, plate} -> {mile, timestamp}
  # pending_tickets: road -> Message.Ticket[]
  # sent_tickets: MapSet({day, plate})
  defstruct limits: %{}, records: %{}, pending_tickets: %{}, sent_tickets: MapSet.new()

  def start_link([]) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  @impl true
  def init(:no_args) do
    {:ok, %__MODULE__{}}
  end

  ## Public API

  def add_road(road, limit) do
    GenServer.cast(__MODULE__, {:add_road, road, limit})
  end

  def add_record(road, plate, mile, timestamp) do
    GenServer.cast(__MODULE__, {:add_record, road, plate, mile, timestamp})
  end

  @impl true
  def handle_info(message, state)

  def handle_info(
        {:register, DispatcherRegistry, road, _partition, _value},
        %__MODULE__{} = state
      ) do
    {left, sent} =
      dispatch_tickets_to_available_dispatchers(
        Map.get(state.pending_tickets, road, []),
        state.sent_tickets,
        road
      )

    state = put_in(state, [Access.key!(:pending_tickets), road], left)
    state = put_in(state.sent_tickets, sent)

    {:noreply, state}
  end

  # We don't need to to anyting here
  def handle_info({:unregister, DispatcherRegistry, _dispatcher, _partition}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_road, road, limit}, state) do
    state = put_in(state, [Access.key!(:limits), road], limit)
    {:noreply, state}
  end

  def handle_cast({:add_record, road, plate, mile, timestamp}, %__MODULE__{} = state) do
    records = Map.get(state.records, {road, plate}, [])
    records = [{mile, timestamp} | records]

    tickets = Util.calc_tickets(records, state.limits[road], road, plate)

    {left, sent} = dispatch_tickets_to_available_dispatchers(tickets, state.sent_tickets, road)

    # TDOO: need a way to clean up records, this will cause memory leak now
    state = put_in(state, [Access.key!(:records), {road, plate}], records)
    state = put_in(state, [Access.key!(:pending_tickets), road], left)
    state = put_in(state.sent_tickets, sent)

    {:noreply, state}
  end

  ## Helpers

  defp dispatch_tickets_to_available_dispatchers([], sent, _road), do: {[], sent}

  defp dispatch_tickets_to_available_dispatchers(tickets, sent, road) do
    Enum.flat_map_reduce(
      tickets,
      sent,
      fn ticket, acc ->
        case Registry.lookup(DispatcherRegistry, road) do
          [] ->
            Logger.debug("No dispatchers availble for #{road}, keeping ticket")
            {[ticket], acc}

          dispatchers ->
            ticket_start_day = floor(ticket.timestamp1 / 86_400)
            ticket_end_day = floor(ticket.timestamp2 / 86_400)
            plate = ticket.plate

            if Enum.any?(ticket_start_day..ticket_end_day, fn d ->
                 MapSet.member?(acc, {d, plate})
               end) do
              {[], acc}
            else
              {pid, _} = Enum.random(dispatchers)
              GenServer.cast(pid, {:send_ticket, ticket})

              new_acc = for d <- ticket_start_day..ticket_end_day, into: acc, do: {d, plate}

              {[], new_acc}
            end
        end
      end
    )
  end
end
