defmodule Protohackers.SpeedDaemon.Util do
  alias Protohackers.SpeedDaemon.Message.Ticket

  def calc_tickets(records, limit, road, plate) do
    records =
      records
      |> Enum.sort_by(fn {_mile, timestamp} -> timestamp end)
      # this is only a safe call
      |> Enum.dedup_by(fn {_mile, timestamp} -> timestamp end)

    records
    |> Enum.zip(Enum.drop(records, 1))
    |> Enum.flat_map(fn {{mile1, ts1}, {mile2, ts2}} ->
      distance = abs(mile1 - mile2)
      avg_speed = round(distance / (ts2 - ts1) * 3600)

      if avg_speed > limit do
        [
          %Ticket{
            road: road,
            plate: plate,
            mile1: mile1,
            timestamp1: ts1,
            mile2: mile2,
            timestamp2: ts2,
            speed: avg_speed * 100
          }
        ]
      else
        []
      end
    end)
  end
end
