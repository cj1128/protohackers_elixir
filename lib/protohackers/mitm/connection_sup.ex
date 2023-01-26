defmodule Protohackers.MITM.ConnectionSup do
  use DynamicSupervisor
  require Logger
  alias Protohackers.MITM.Connection

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  @impl true
  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 50)
  end

  def start_child(incoming_socket) do
    DynamicSupervisor.start_child(__MODULE__, {Connection, incoming_socket})
  end
end
