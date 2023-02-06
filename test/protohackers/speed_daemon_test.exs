defmodule SpeedDaemon.IntegrationTest do
  use ExUnit.Case

  alias Protohackers.SpeedDaemon.Message

  test "ticketing a single car" do
    {:ok, camera1} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    {:ok, camera2} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    {:ok, dispatcher} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])

    send_message(dispatcher, %Message.IAmDispatcher{roads: [101]})

    send_message(camera1, %Message.IAmCamera{road: 101, mile: 4452, limit: 100})
    send_message(camera1, %Message.Plate{plate: "A1", timestamp: 203_663})

    send_message(camera2, %Message.IAmCamera{road: 101, mile: 4462, limit: 100})
    send_message(camera2, %Message.Plate{plate: "A1", timestamp: 203_963})

    assert_receive {:tcp, ^dispatcher, data}
    assert {:ok, message, <<>>} = Message.decode(data)

    assert message == %Message.Ticket{
             mile1: 4452,
             mile2: 4462,
             plate: "A1",
             road: 101,
             speed: 12000,
             timestamp1: 203_663,
             timestamp2: 203_963
           }
  end

  test "ticketing multiple cars2" do
    {:ok, camera1} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    {:ok, camera2} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    {:ok, dispatcher} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])

    send_message(camera1, %Message.IAmCamera{road: 102, mile: 4452, limit: 100})
    send_message(camera2, %Message.IAmCamera{road: 102, mile: 4462, limit: 100})

    send_message(camera1, %Message.Plate{plate: "D1", timestamp: 203_663})
    send_message(camera2, %Message.Plate{plate: "D1", timestamp: 203_963})

    send_message(camera1, %Message.Plate{plate: "D2", timestamp: 0})
    send_message(camera2, %Message.Plate{plate: "D2", timestamp: 300})

    :timer.sleep(100)
    send_message(dispatcher, %Message.IAmDispatcher{roads: [102]})

    assert_receive {:tcp, ^dispatcher, _data}
    assert_receive {:tcp, ^dispatcher, _data}
  end

  test "ticketing multiple cars" do
    {:ok, camera1} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    {:ok, camera2} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    {:ok, camera3} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    {:ok, camera4} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    {:ok, dispatcher} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])

    send_message(dispatcher, %Message.IAmDispatcher{roads: [104]})

    send_message(camera1, %Message.IAmCamera{road: 104, mile: 4452, limit: 100})
    send_message(camera2, %Message.IAmCamera{road: 104, mile: 4462, limit: 100})
    send_message(camera3, %Message.IAmCamera{road: 104, mile: 4472, limit: 100})
    send_message(camera4, %Message.IAmCamera{road: 104, mile: 4482, limit: 100})

    send_message(camera1, %Message.Plate{plate: "B1", timestamp: 203_663})
    send_message(camera2, %Message.Plate{plate: "B1", timestamp: 203_963})

    assert_receive {:tcp, ^dispatcher, data}
    assert {:ok, message, <<>>} = Message.decode(data)

    assert message == %Message.Ticket{
             mile1: 4452,
             mile2: 4462,
             plate: "B1",
             road: 104,
             speed: 12000,
             timestamp1: 203_663,
             timestamp2: 203_963
           }

    send_message(camera1, %Message.Plate{plate: "B3", timestamp: 86200})
    send_message(camera2, %Message.Plate{plate: "B2", timestamp: 0})
    send_message(camera3, %Message.Plate{plate: "B2", timestamp: 300})
    assert_receive {:tcp, ^dispatcher, data}
    assert {:ok, message, <<>>} = Message.decode(data)

    assert message == %Message.Ticket{
             mile1: 4462,
             mile2: 4472,
             plate: "B2",
             road: 104,
             speed: 12000,
             timestamp1: 0,
             timestamp2: 300
           }

    send_message(camera2, %Message.Plate{plate: "B3", timestamp: 86300})
    assert_receive {:tcp, ^dispatcher, data}
    assert {:ok, message, <<>>} = Message.decode(data)

    assert message == %Message.Ticket{
             mile1: 4452,
             mile2: 4462,
             plate: "B3",
             road: 104,
             speed: 36000,
             timestamp1: 86200,
             timestamp2: 86300
           }

    send_message(camera3, %Message.Plate{plate: "B3", timestamp: 86500})
    refute_receive {:tcp, ^dispatcher, _data}

    send_message(camera4, %Message.Plate{plate: "B3", timestamp: 86700})
    assert_receive {:tcp, ^dispatcher, data}
    assert {:ok, message, <<>>} = Message.decode(data)

    assert message == %Message.Ticket{
             mile1: 4472,
             mile2: 4482,
             plate: "B3",
             road: 104,
             speed: 18000,
             timestamp1: 86500,
             timestamp2: 86700
           }
  end

  test "one ticket for same car per day" do
    {:ok, camera1} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    {:ok, camera2} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    {:ok, camera3} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    send_message(camera1, %Message.IAmCamera{road: 105, mile: 4452, limit: 100})
    send_message(camera2, %Message.IAmCamera{road: 105, mile: 4462, limit: 100})
    send_message(camera3, %Message.IAmCamera{road: 105, mile: 4472, limit: 100})

    send_message(camera1, %Message.Plate{plate: "C1", timestamp: 100})
    send_message(camera2, %Message.Plate{plate: "C1", timestamp: 400})
    send_message(camera3, %Message.Plate{plate: "C1", timestamp: 700})

    {:ok, dispatcher} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    send_message(dispatcher, %Message.IAmDispatcher{roads: [105]})

    assert_receive {:tcp, ^dispatcher, data}
    assert {:ok, message, <<>>} = Message.decode(data)

    assert %Message.Ticket{} = message
    refute_receive {:tcp, ^dispatcher, _data}
  end

  test "pending tickets get flushed" do
    {:ok, camera1} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    {:ok, camera2} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    send_message(camera1, %Message.IAmCamera{road: 582, mile: 4452, limit: 100})
    send_message(camera2, %Message.IAmCamera{road: 582, mile: 4462, limit: 100})
    send_message(camera1, %Message.Plate{plate: "IT43PRC", timestamp: 203_663})
    send_message(camera2, %Message.Plate{plate: "IT43PRC", timestamp: 203_963})

    # We now have a tickets on road 582, but no dispatcher for it.

    {:ok, dispatcher} = :gen_tcp.connect(~c"localhost", 5007, [:binary, active: true])
    send_message(dispatcher, %Message.IAmDispatcher{roads: [582]})

    assert_receive {:tcp, ^dispatcher, data}
    assert {:ok, message, <<>>} = Message.decode(data)

    assert message == %Message.Ticket{
             mile1: 4452,
             mile2: 4462,
             plate: "IT43PRC",
             road: 582,
             speed: 12000,
             timestamp1: 203_663,
             timestamp2: 203_963
           }
  end

  defp send_message(socket, message) do
    assert :ok = :gen_tcp.send(socket, Message.encode(message))
  end
end
