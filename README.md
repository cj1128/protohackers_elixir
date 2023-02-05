# Protohackers in Elixir

This is my implementation of the [Protohackers](https://protohackers.com/) problems.

Start the project by running `mix run --no-halt`.

## Problems

- 00: Smoke test, , `echo_server.ex`, port 5001
- 01: Prime time, `prime_server.ex`, port 5002
- 02: Means to an end, `price_server.ex`, port 5003
- 03: Budget chat, `budget_chat_server.ex`, port 5004
- 04: Unusual database program, `kv_store_server.ex`, port 5005
- 05: Mob in the middle, `mitm_server.ex`, port 5006
- 06: Speed daemon, `speed_daemon_server.ex`, port 5007

## What I Learn

- We can use [jason](https://github.com/michalmuskala/jason) to parse JSONs and then pattern match against them, really convenient
- `packet: :line` of :gen_tcp is really helpful.
- `active` mode of `:gen_tcp` can be really handy
