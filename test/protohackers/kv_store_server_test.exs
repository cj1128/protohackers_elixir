defmodule Protohackers.KvStoreServerTest do
  use ExUnit.Case, async: true

  test "insert and retrieve" do
    {:ok, udp} = :gen_udp.open(0, [:binary, active: false, recbuf: 1000])

    :ok = :gen_udp.send(udp, {127, 0, 0, 1}, 5005, "a")
    assert {:ok, {_address, _port, "a="}} = :gen_udp.recv(udp, 0)

    :ok = :gen_udp.send(udp, {127, 0, 0, 1}, 5005, "a=1")
    :ok = :gen_udp.send(udp, {127, 0, 0, 1}, 5005, "a")
    assert {:ok, {_address, _port, "a=1"}} = :gen_udp.recv(udp, 0)

    :ok = :gen_udp.send(udp, {127, 0, 0, 1}, 5005, "a=2")
    :ok = :gen_udp.send(udp, {127, 0, 0, 1}, 5005, "a")
    assert {:ok, {_address, _port, "a=2"}} = :gen_udp.recv(udp, 0)
  end

  test "verison" do
    {:ok, udp} = :gen_udp.open(0, [:binary, active: false, recbuf: 1000])

    :ok = :gen_udp.send(udp, {127, 0, 0, 1}, 5005, "version")
    assert {:ok, {_address, _port, "version=kvstore1.0"}} = :gen_udp.recv(udp, 0)

    :ok = :gen_udp.send(udp, {127, 0, 0, 1}, 5005, "version=foo")
    :ok = :gen_udp.send(udp, {127, 0, 0, 1}, 5005, "version")
    assert {:ok, {_address, _port, "version=kvstore1.0"}} = :gen_udp.recv(udp, 0)
  end
end
