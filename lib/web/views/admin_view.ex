defmodule Web.AdminView do
  use Web, :view

  def render("mute.json", %{data: data}) do
    %{data: data}
  end
end
