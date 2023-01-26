defmodule Protohackers.MITM.BoguscoinTest do
  use ExUnit.Case, async: true

  alias Protohackers.MITM.Boguscoin
  @target "7YWHMfk9JZe0LM0g1ZauHuiSxhI"

  test "rewrite/1" do
    assert Boguscoin.rewrite("hello") == "hello"

    assert Boguscoin.rewrite("7F1u3wSD5RbOHQmupo9nx4TnhQ") == @target

    assert Boguscoin.rewrite("hello 7F1u3wSD5RbOHQmupo9nx4TnhQ") == "hello #{@target}"

    assert Boguscoin.rewrite("hello 7F1u3wSD5RbOHQmupo9nx4TnhQ world") ==
             "hello #{@target} world"

    assert Boguscoin.rewrite("7F1u3wSD5RbO") == "7F1u3wSD5RbO"
    assert Boguscoin.rewrite("X7F1u3wSD5RbOHQmupo9nx4TnhQ") == "X7F1u3wSD5RbOHQmupo9nx4TnhQ"
  end
end
