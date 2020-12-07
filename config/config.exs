# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :janus_ws_example, Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4Pn8FK3iz4GRvLJ2ZC0+gRJyO+ZxvYoYQSWBKDvTG/kVXeGyZlKFpoM9vf339ujw",
  render_errors: [view: Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: JanusEx.PubSub, adapter: Phoenix.PubSub.PG2]

config :janus_ws_example, JanusEx.Room, interact_with_janus?: true

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
