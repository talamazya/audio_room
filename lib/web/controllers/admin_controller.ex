defmodule Web.AdminController do
  use Web, :controller

  alias JanusEx.Admin

  def mute(conn, params) do
    %{"room_id" => room_id, "participant_id" => participant_id, "mute" => mute?} = params

    with {:ok, msg} <-
           Admin.mute(
             String.to_integer(room_id),
             String.to_integer(participant_id),
             String.to_existing_atom(mute?)
           ) do
      conn
      |> put_status(200)
      |> render("mute.json", data: %{"mute" => "success", "msg" => msg})
    else
      {:error, msg} ->
        conn
        |> put_status(422)
        |> render("mute.json", data: %{"mute" => "failed", "msg" => msg})
    end
  end
end
