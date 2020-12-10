defmodule JanusEx.JanusApi.Plugin.AudioBridge.RestApi.AdminService do
  alias JanusEx.JanusApi.Plugin.AudioBridge.Response
  alias JanusEx.RestApi.RestClient
  alias JanusEx.Plugin.Util

  def mute(session_id, handle_id, room_id, participant_id, mute?) do
    request = if mute?, do: "mute", else: "unmute"

    body = %{
      "request" => request,
      "room" => room_id,
      "id" => participant_id
    }

    data = %{janus: "message", transaction: Util.transaction(), body: body}

    with {:ok, msg} <- RestClient.post("janus/#{session_id}/#{handle_id}", data),
         data <- Response.from_session(msg, session_id, handle_id),
         {:ok, res} <- Response.from_mute(data, room_id) do
      {:ok, res}
    else
      {:error, data} -> {:error, data}
      _ -> {:error, nil}
    end
  end
end
