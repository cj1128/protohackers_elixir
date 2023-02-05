import Config

log_level =
  if config_env() == :test do
    :debug
  else
    :debug
  end

config :logger, level: log_level
config :logger, :console, metadata: [:type, :road, :mile]
