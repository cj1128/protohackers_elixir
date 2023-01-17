defmodule Protohackers.PrimeServerTest do
  use ExUnit.Case, async: true

  @tag :capture_log
  test "only handles json" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5002, mode: :binary, active: false)
    assert :gen_tcp.send(socket, "not a json\n") == :ok
    :gen_tcp.shutdown(socket, :write)
    assert :gen_tcp.recv(socket, 0, 5000) == {:ok, "malformed request\n"}
  end

  @tag :capture_log
  test "json must be in valid schema" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5002, mode: :binary, active: false)
    assert :gen_tcp.send(socket, [Jason.encode!(%{method: :isPrime}), ?\n]) == :ok
    :gen_tcp.shutdown(socket, :write)
    assert :gen_tcp.recv(socket, 0, 5000) == {:ok, "malformed request\n"}
  end

  test "receives valid response" do
    cases = [
      {1, false},
      {2, true},
      {3, true},
      {5, true},
      {9, false},
      {10, false},
      {11, true},
      {13, true},
      {15, false}
    ]

    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5002, mode: :binary, active: false)

    payload =
      cases
      |> Enum.map(&Jason.encode!(%{method: :isPrime, number: elem(&1, 0)}))
      |> Enum.join("\n")

    assert :gen_tcp.send(socket, [payload, ?\n]) == :ok
    :gen_tcp.shutdown(socket, :write)

    assert {:ok, data} = recv_until_closed(socket, _buffer = "")

    String.split(data, "\n", trim: true)
    |> Enum.with_index()
    |> Enum.each(fn {line, i} ->
      {input, expect} = Enum.at(cases, i)
      assert %{"method" => "isPrime", "prime" => result} = Jason.decode!(line)
      assert result == expect, "is_prime of #{input}, got #{result}, expect #{expect}"
    end)
  end

  defp recv_until_closed(socket, buffer) do
    case :gen_tcp.recv(socket, 0, 5000) do
      {:ok, data} ->
        recv_until_closed(socket, [buffer, data])

      {:error, :closed} ->
        {:ok, IO.iodata_to_binary(buffer)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
