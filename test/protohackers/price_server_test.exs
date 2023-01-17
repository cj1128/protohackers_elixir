defmodule Protohackers.PriceServerTest do
  use ExUnit.Case

  test "handle requests" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5003, mode: :binary, active: false)

    :ok = :gen_tcp.send(socket, <<?I, 1::32-signed-big, 100::32-signed-big>>)
    :ok = :gen_tcp.send(socket, <<?I, 2::32-signed-big, 200::32-signed-big>>)
    :ok = :gen_tcp.send(socket, <<?I, 3::32-signed-big, 300::32-signed-big>>)

    :gen_tcp.send(socket, <<?Q, 1::32-signed-big, 3::32-signed-big>>)
    assert {:ok, <<200::32-signed-big>>} = :gen_tcp.recv(socket, 4, 100_000)
  end

  test "handle clients separately" do
    {:ok, socket1} = :gen_tcp.connect(~c"localhost", 5003, mode: :binary, active: false)
    {:ok, socket2} = :gen_tcp.connect(~c"localhost", 5003, mode: :binary, active: false)

    :ok = :gen_tcp.send(socket1, <<?I, 1::32-signed-big, 100::32-signed-big>>)
    :ok = :gen_tcp.send(socket1, <<?I, 2::32-signed-big, 200::32-signed-big>>)
    :ok = :gen_tcp.send(socket2, <<?I, 3::32-signed-big, 300::32-signed-big>>)

    :gen_tcp.send(socket1, <<?Q, 1::32-signed-big, 3::32-signed-big>>)
    assert {:ok, <<150::32-signed-big>>} = :gen_tcp.recv(socket1, 4, 100_000)

    :gen_tcp.send(socket2, <<?Q, 1::32-signed-big, 3::32-signed-big>>)
    assert {:ok, <<300::32-signed-big>>} = :gen_tcp.recv(socket2, 4, 100_000)
  end
end
