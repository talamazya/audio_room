use Mix.Config

config :audio_room, Web.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  version: Application.spec(:audio_room, :vsn),
  server: true,
  root: "."

config :logger, level: :warn
