defmodule Protohackers.SpeedDaemon.ConnectionSup do
  use DynamicSupervisor
  require Logger
  alias Protohackers.SpeedDaemon.Connection

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  @impl true
  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 1000)
  end

  def start_child(socket) do
    DynamicSupervisor.start_child(__MODULE__, {Connection, socket})
  end
end
