defmodule Protohackers.EchoServerTest do
  use ExUnit.Case

  test "echoes anything back" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5001, mode: :binary, active: false)
    assert :gen_tcp.send(socket, "foo") == :ok
    assert :gen_tcp.send(socket, "bar") == :ok
    :gen_tcp.shutdown(socket, :write)
    assert :gen_tcp.recv(socket, 0, 5000) == {:ok, "foobar"}
  end

  test "echo server has a buffer limit" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5001, mode: :binary, active: false)
    assert :gen_tcp.send(socket, :binary.copy("a", 100 * 1024 + 1)) == :ok
    assert :gen_tcp.recv(socket, 0) == {:error, :closed}
  end

  test "handles concurrent connections" do
    tasks =
      for _ <- 1..4 do
        Task.async(fn ->
          {:ok, socket} = :gen_tcp.connect(~c"localhost", 5001, mode: :binary, active: false)
          assert :gen_tcp.send(socket, "foo") == :ok
          assert :gen_tcp.send(socket, "bar") == :ok
          :gen_tcp.shutdown(socket, :write)
          assert :gen_tcp.recv(socket, 0, 5000) == {:ok, "foobar"}
        end)
      end

    Enum.each(tasks, &Task.await/1)
  end
end
