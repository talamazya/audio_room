use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :audio_room, Web.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :audio_room, JanusEx.Room, interact_with_janus?: false

config :audio_room, JanusEx.JanusChannel, offer_mock?: true

config :audio_room, JanusEx.JanusChannel, candidate_mock?: true

config :audio_room, JanusEx.JanusChannel, gimme_offer_mock?: true
