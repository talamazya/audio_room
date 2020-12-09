defmodule Web.RoomView do
  use Web, :view

  def render("index.json", %{rooms: rooms}) do
    %{data: rooms}
  end
end
