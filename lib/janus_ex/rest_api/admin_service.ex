defmodule JanusEx.RestApi.AdminService do
  alias JanusEx.RestApi.RestClient
  alias JanusEx.RestApi.Util

  def mute(session_id, handle_id, room_id, participant_id, mute?) do
    request = if mute?, do: "mute", else: "unmute"

    body = %{
      "request" => request,
      "room" => room_id,
      "id" => participant_id
    }

    data = %{janus: "message", transaction: Util.transaction(), body: body}

    case RestClient.post("janus/#{session_id}/#{handle_id}", data) do
      {:ok,
       %{
         "janus" => "success",
         "plugindata" => %{
           "data" => %{"audiobridge" => "success", "room" => ^room_id},
           "plugin" => "janus.plugin.audiobridge"
         },
         "sender" => ^handle_id,
         "session_id" => ^session_id,
         "transaction" => _
       }} ->
        {:ok, :success}

      {:ok,
       %{
         "janus" => "success",
         "plugindata" => %{
           "data" => %{"audiobridge" => "success"},
           "plugin" => "janus.plugin.audiobridge"
         },
         "sender" => ^handle_id,
         "session_id" => ^session_id,
         "transaction" => _
       }} ->
        {:ok, :already_muted}

      {:ok,
       %{
         "janus" => "success",
         "plugindata" => %{
           "data" => data,
           "plugin" => "janus.plugin.audiobridge"
         },
         "sender" => ^handle_id,
         "session_id" => ^session_id,
         "transaction" => _
       }} ->
        {:error, data}

      _ ->
        {:error, nil}
    end
  end
end
