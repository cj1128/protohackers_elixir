defmodule Protohackers.BudgetChatServerTest do
  use ExUnit.Case, async: true

  test "whole flow" do
    {:ok, socket1} =
      :gen_tcp.connect(~c"localhost", 5004, mode: :binary, active: false, packet: :line)

    {:ok, socket2} =
      :gen_tcp.connect(~c"localhost", 5004, mode: :binary, active: false, packet: :line)

    assert {:ok, "Welcome to budgetchat! What's your name?\n"} =
             :gen_tcp.recv(socket1, 0, 300_000)

    :ok = :gen_tcp.send(socket1, "socket1\n")
    assert {:ok, "* The room contains: \n"} = :gen_tcp.recv(socket1, 0, 300_000)

    assert {:ok, "Welcome to budgetchat! What's your name?\n"} =
             :gen_tcp.recv(socket2, 0, 300_000)

    :ok = :gen_tcp.send(socket2, "socket2\n")
    assert {:ok, "* The room contains: socket1\n"} = :gen_tcp.recv(socket2, 0, 300_000)
    assert {:ok, "* socket2 has joined the room\n"} = :gen_tcp.recv(socket1, 0, 300_000)

    :ok = :gen_tcp.send(socket1, "hello from socket1\n")
    assert {:ok, "[socket1] hello from socket1\n"} = :gen_tcp.recv(socket2, 0, 300_000)

    :ok = :gen_tcp.send(socket2, "hello there\n")
    assert {:ok, "[socket2] hello there\n"} = :gen_tcp.recv(socket1, 0, 300_000)

    :gen_tcp.close(socket1)
    assert {:ok, "* socket1 has left the room\n"} = :gen_tcp.recv(socket2, 0, 300_000)

    {:ok, socket3} =
      :gen_tcp.connect(~c"localhost", 5004, mode: :binary, active: false, packet: :line)

    assert {:ok, "Welcome to budgetchat! What's your name?\n"} =
             :gen_tcp.recv(socket3, 0, 300_000)

    :ok = :gen_tcp.send(socket3, "socket3\n")
    assert {:ok, "* The room contains: socket2\n"} = :gen_tcp.recv(socket3, 0, 300_000)

    assert {:ok, "* socket3 has joined the room\n"} = :gen_tcp.recv(socket2, 0, 300_000)
  end
end
