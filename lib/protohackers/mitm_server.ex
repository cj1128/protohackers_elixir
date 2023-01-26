defmodule Protohackers.MITMServer do
  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, :no_args)
  end

  def init(:no_args) do
    children_spec = [
      Protohackers.MITM.ConnectionSup,
      Protohackers.MITM.Acceptor
    ]

    Supervisor.init(children_spec, strategy: :rest_for_one)
  end
end
