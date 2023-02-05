defmodule Protohackers.SpeedDaemon.Message do
  # Client -> server

  defmodule Plate do
    defstruct [:plate, :timestamp]
  end

  defmodule WantHeartbeat do
    defstruct [:interval]
  end

  defmodule IAmCamera do
    defstruct [:road, :mile, :limit]
  end

  defmodule IAmDispatcher do
    defstruct [:roads]
  end

  # Server -> client

  defmodule Ticket do
    # speed: 100x miles per hour
    defstruct [:plate, :road, :mile1, :timestamp1, :mile2, :timestamp2, :speed]
  end

  defmodule Heartbeat do
    defstruct []
  end

  defmodule Error do
    defstruct msg: ""
  end

  @msg_types [0x10, 0x20, 0x21, 0x40, 0x41, 0x80, 0x81]

  # Encoding

  def encode(msg)

  def encode(%Error{msg: msg}) do
    <<0x10, byte_size(msg), msg::binary>>
  end

  def encode(%Plate{plate: plate, timestamp: timestamp}) do
    <<0x20, byte_size(plate), plate::binary, timestamp::32>>
  end

  def encode(%Ticket{
        plate: plate,
        road: road,
        mile1: mile1,
        timestamp1: timestamp1,
        mile2: mile2,
        timestamp2: timestamp2,
        speed: speed
      }) do
    <<0x21, byte_size(plate), plate::binary, road::16, mile1::16, timestamp1::32, mile2::16,
      timestamp2::32, speed::16>>
  end

  def encode(%WantHeartbeat{interval: interval}) do
    <<0x40, interval::32>>
  end

  def encode(%Heartbeat{}) do
    <<0x41>>
  end

  def encode(%IAmCamera{road: road, mile: mile, limit: limit}) do
    <<0x80, road::16, mile::16, limit::16>>
  end

  def encode(%IAmDispatcher{roads: roads}) do
    encoded_roads = IO.iodata_to_binary(for road <- roads, do: <<road::16>>)
    <<0x81, length(roads), encoded_roads::binary>>
  end

  # Decoding

  # {:ok, msg, rest} | :error | :incomplete
  def decode(msg)

  # Error
  def decode(<<0x10, msg_size::8, msg::binary-size(msg_size), rest::binary>>) do
    {:ok, %Error{msg: msg}, rest}
  end

  # Plate
  def decode(<<0x20, plate_size::8, plate::binary-size(plate_size), timestamp::32, rest::binary>>) do
    {:ok, %Plate{plate: plate, timestamp: timestamp}, rest}
  end

  # Ticket
  def decode(
        <<0x21, plate_size::8, plate::binary-size(plate_size), road::16, mile1::16,
          timestamp1::32, mile2::16, timestamp2::32, speed::16, rest::binary>>
      ) do
    {:ok,
     %Ticket{
       plate: plate,
       road: road,
       mile1: mile1,
       timestamp1: timestamp1,
       mile2: mile2,
       timestamp2: timestamp2,
       speed: speed
     }, rest}
  end

  # WantHeartbeat
  def decode(<<0x40, interval::32, rest::binary>>) do
    {:ok, %WantHeartbeat{interval: interval}, rest}
  end

  # Heartbeat
  def decode(<<0x41, rest::binary>>) do
    {:ok, %Heartbeat{}, rest}
  end

  # IAmCamera
  def decode(<<0x80, road::16, mile::16, limit::16, rest::binary>>) do
    {:ok, %IAmCamera{road: road, mile: mile, limit: limit}, rest}
  end

  # IAmDispatcher
  def decode(<<0x81, numroads::8, roads::binary-size(numroads * 2), rest::binary>>) do
    roads = for <<road::16 <- roads>>, do: road
    {:ok, %IAmDispatcher{roads: roads}, rest}
  end

  def decode(<<type::8, _rest::binary>>) when type in @msg_types do
    :incomplete
  end

  def decode(<<_type::8, _rest::binary>>) do
    :error
  end

  def decode(<<>>) do
    :incomplete
  end
end
