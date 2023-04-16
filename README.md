# Protohackers in Elixir

This is my implementation of the [Protohackers](https://protohackers.com/) problems.

Start the project by running `mix run --no-halt`.

## Problems

How to run:

```shell
$ mix run --no-halt
```

All servers are using port `8888`. I have opened this port in my computer to be accessible from the internet, so there is no need to deploy.

- 00: Smoke test, , `echo_server.ex`
- 01: Prime time, `prime_server.ex`
- 02: Means to an end, `price_server.ex`
- 03: Budget chat, `budget_chat_server.ex`
- 04: Unusual database program, `kv_store_server.ex`
- 05: Mob in the middle, `mitm_sup.ex`
- 06: Speed daemon, `speed_daemon_sup.ex`

## What I Learn

- We can use [jason](https://github.com/michalmuskala/jason) to parse JSONs and then pattern match against them, really convenient
- `packet: :line` of :gen_tcp is really helpful.
- `active` mode of `:gen_tcp` can be really handy
