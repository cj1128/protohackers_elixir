defmodule Protohackers.PriceServer.DB do
  def new() do
    []
  end

  def add(db, timestamp, price)
      when is_list(db) and is_integer(timestamp) and is_integer(price) do
    [{timestamp, price} | db]
  end

  def query(db, mintime, maxtime)
      when is_list(db) and is_integer(mintime) and is_integer(maxtime) do
    db
    |> Enum.filter(fn {timestamp, _price} -> timestamp >= mintime && timestamp <= maxtime end)
    |> Enum.reduce({0, 0}, fn {_, price}, {total, count} -> {total + price, count + 1} end)
    |> then(fn
      {_, 0} -> 0
      {total, count} -> div(total, count)
    end)
  end
end
