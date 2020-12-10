defmodule JanusEx.JanusApi.Plugin.AudioBridge.Websocket.AudioBridge do
  alias Janus.WS, as: Janus
  alias JanusEx.JanusApi.Plugin.AudioBridge.Response

  @client Janus
  @plugin "janus.plugin.audiobridge"

  def plugin_name() do
    @plugin
  end

  def create_session() do
    Janus.create_session(@client)
  end

  def attach(session_id) do
    Janus.attach(@client, session_id, @plugin)
  end

  def attach_response(msg, session_id) do
    Response.from_attach(msg, session_id)
  end

  def create(session_id, handle_id, room_id, description \\ "") do
    body = %{
      "request" => "create",
      "room" => room_id,
      "description" => description
    }

    msg = %{"body" => body}

    Janus.send_message(@client, session_id, handle_id, msg)
  end

  def create_response(
        %{"plugindata" => %{"data" => %{"audiobridge" => "event"}}} = msg,
        session_id,
        handle_id
      ) do
    msg
    |> Response.from_session(session_id, handle_id)
    |> Response.from_room_existed()
    |> String.split()
    |> Enum.at(1)
    |> String.to_integer()
  end

  def create_response(
        %{"plugindata" => %{"data" => %{"audiobridge" => "created"}}} = msg,
        session_id,
        handle_id
      ) do
    msg
    |> Response.from_session(session_id, handle_id)
    |> Response.from_room_create_successfully()
  end

  def join(session_id, handle_id, room_id) do
    body = %{"request" => "join", "room" => room_id}
    msg = %{"body" => body}

    Janus.send_message(@client, session_id, handle_id, msg)
  end

  def join_response(session_id, handle_id, msg) do
    msg
    |> Response.from_session(session_id, handle_id, "event")
    |> Response.from_join()
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

  def participants(session_id, handle_id, room_id) do
    msg = %{"body" => %{"request" => "listparticipants", "room" => room_id}}

    Janus.send_message(@client, session_id, handle_id, msg)
  end

  def participants_response(session_id, handle_id, room_id, msg) do
    msg
    |> Response.from_session(session_id, handle_id)
    |> Response.from_participants(room_id)
  end

  def mute(session_id, handle_id, room_id, participant_id) do
    body = %{
      "request" => "mute",
      "room" => room_id,
      "id" => participant_id,
      "secret" => "123"
    }

    msg = %{"body" => body}
    Janus.send_message(@client, session_id, handle_id, msg)
  end
end
