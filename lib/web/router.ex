defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers
  end

  scope "/", Web do
    pipe_through :browser

    get "/rooms", RoomController, :index
    get "/rooms/:room_name", RoomController, :show
    post "/rooms/:room_name/messages", MessageController, :create
    put "/rooms/:room_name/messages", MessageController, :create

    put "/admin/mute/:mute/:room_id/:participant_id", AdminController, :mute
  end
end
