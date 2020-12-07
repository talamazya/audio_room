defmodule JanusEx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # TODO could the room supervisor be a listener
      JanusEx.Room.Registry.Listener,
      {Registry,
       name: JanusEx.Room.Registry, keys: :unique, listeners: [JanusEx.Room.Registry.Listener]},
      JanusEx.Room.Supervisor,
      {Registry, keys: :duplicate, name: Janus.WS.Session.Registry},
      {Janus.WS, url: "ws://localhost:8188", registry: Janus.WS.Session.Registry, name: Janus.WS},
      Web.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JanusEx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
