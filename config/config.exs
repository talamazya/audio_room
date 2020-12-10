# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :audio_room, Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4Pn8FK3iz4GRvLJ2ZC0+gRJyO+ZxvYoYQSWBKDvTG/kVXeGyZlKFpoM9vf339ujw",
  render_errors: [view: Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: JanusEx.PubSub, adapter: Phoenix.PubSub.PG2]

config :audio_room, JanusEx.Room, interact_with_janus?: true

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :audio_room, :janus,
  admin_secret: "janusoverlord",
  admin_http_port: 8088,
  admin_path: "/admin",
  api_secret: "api_secret",
  host: "localhost",
  http_port: 8088,
  http_protocol: "http",
  path: "/janus",
  ws_port: 8188,
  ws_protocol: "websocket"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
