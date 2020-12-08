defmodule JanusEx.JanusApi.Plugin.AudioBridge.AudioBridge do
  alias Janus.WS, as: Janus

  @client Janus
  @plugin "janus.plugin.audiobridge"

  def create_session() do
    Janus.create_session(@client)
  end

  def attach(session_id) do
    Janus.attach(@client, session_id, @plugin)
  end

  def attach_response(msg, session_id) do
    %{
      "janus" => "success",
      "session_id" => ^session_id,
      "data" => %{"id" => handle_id}
    } = msg

    handle_id
  end

  def join(session_id, handle_id, room_id) do
    msg = %{
      "body" => %{
        "request" => "join",
        "room" => room_id
      }
    }

    Janus.send_message(@client, session_id, handle_id, msg)
  end

  def join_response(session_id, handle_id, msg) do
    %{
      "janus" => "event",
      "plugindata" => %{
        "data" => %{
          "audiobridge" => "joined",
          "id" => participant_id,
          "participants" => _,
          "room" => room_id
        },
        "plugin" => @plugin
      },
      "sender" => ^handle_id,
      "session_id" => ^session_id,
      "transaction" => _
    } = msg

    {participant_id, room_id}
  end

  def offer(session_id, handle_id, offer) do
    body = %{"request" => "configure"}
    msg = %{"jsep" => offer, "body" => body}

    Janus.send_message(@client, session_id, handle_id, msg)
  end

  def trickle_candidate(session_id, handle_id, candidate) do
    Janus.send_trickle_candidate(@client, session_id, handle_id, candidate)
  end

  def keep_alive(session_id) do
    Janus.send_keepalive(@client, session_id)
  end
end

# Janus.send_message(@client, session_id, handle_id, %{
#   "body" => %{"request" => "listparticipants", "room" => Map.get(state, :room_id)}
# })
