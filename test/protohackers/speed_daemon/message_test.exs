defmodule Protohackers.SpeedDaemon.MessageTest do
  use ExUnit.Case, async: true

  alias Protohackers.SpeedDaemon.Message

  alias Protohackers.SpeedDaemon.Message.{
    Error,
    Plate,
    Ticket,
    WantHeartbeat,
    Heartbeat,
    IAmCamera,
    IAmDispatcher
  }

  test "encode" do
    assert Message.encode(%Error{msg: "abc"}) == <<0x10, 3, "abc">>

    assert Message.encode(%Plate{plate: "UN1X", timestamp: 1000}) ==
             <<0x20, 4, "UN1X", 1000::32>>

    assert Message.encode(%Ticket{
             plate: "UN1X",
             road: 66,
             mile1: 100,
             timestamp1: 123_456,
             mile2: 110,
             timestamp2: 123_816,
             speed: 10000
           }) ==
             <<0x21, 4, "UN1X", 66::16, 100::16, 123_456::32, 110::16, 123_816::32, 10000::16>>

    assert Message.encode(%WantHeartbeat{interval: 10}) == <<0x40, 10::32>>

    assert Message.encode(%Heartbeat{}) == <<0x41>>

    assert Message.encode(%IAmCamera{road: 66, mile: 100, limit: 60}) ==
             <<0x80, 66::16, 100::16, 60::16>>

    assert Message.encode(%IAmDispatcher{roads: [66, 368, 5000]}) ==
             <<0x81, 3, 66::16, 368::16, 5000::16>>
  end

  test "decode" do
    msgs = [
      %Error{msg: "error"},
      %Plate{plate: "p1", timestamp: 123},
      %Ticket{
        plate: "p2",
        road: 1,
        mile1: 1,
        timestamp1: 321_123,
        mile2: 200,
        timestamp2: 456_789,
        speed: 20000
      },
      %WantHeartbeat{interval: 123},
      %Heartbeat{},
      %IAmCamera{road: 1, mile: 2, limit: 80},
      %IAmDispatcher{roads: [1, 2, 3]}
    ]

    for msg <- msgs do
      assert Message.decode(Message.encode(msg)) == {:ok, msg, <<>>}
    end

    assert Message.decode(<<>>) == :incomplete
    assert Message.decode(<<0x80>>) == :incomplete
    assert Message.decode(<<0x00>>) == :error
  end
end
