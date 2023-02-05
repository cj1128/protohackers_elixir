defmodule Protohackers.SpeedDaemonSup do
  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, :no_args)
  end

  def init(:no_args) do
    children_spec = [
      {Registry,
       keys: :duplicate,
       name: Protohackers.SpeedDaemon.DispatcherRegistry,
       listeners: [Protohackers.SpeedDaemon.Processor]},
      Protohackers.SpeedDaemon.Processor,
      Protohackers.SpeedDaemon.ConnectionSup,
      Protohackers.SpeedDaemon.Acceptor
    ]

    Supervisor.init(children_spec, strategy: :rest_for_one)
  end
end
