defmodule Protohackers.PriceServer.DBTest do
  use ExUnit.Case
  alias Protohackers.PriceServer.DB

  test "adding elements and getting the average" do
    db = DB.new()

    assert DB.query(db, 1, 100) == 0

    db =
      db
      |> DB.add(1, 100)
      |> DB.add(2, 200)
      |> DB.add(3, 300)

    assert DB.query(db, 1, 3) == 200
    assert DB.query(db, 1, 2) == 150
    assert DB.query(db, 2, 3) == 250
    assert DB.query(db, 4, 5) == 0
  end
end
