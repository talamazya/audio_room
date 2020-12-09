defmodule JanusEx.JanusApi.Plugin.AudioBridge.AudioBridge do
  alias Janus.WS, as: Janus

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
    %{
      "janus" => "success",
      "session_id" => ^session_id,
      "data" => %{"id" => handle_id}
    } = msg

    handle_id
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
    %{
      "janus" => "success",
      "plugindata" => %{
        "data" => %{
          "audiobridge" => "event",
          # "error" => "Room 112114386 already exists"
          "error" => value,
          "error_code" => 486
        },
        "plugin" => "janus.plugin.audiobridge"
      },
      "sender" => ^handle_id,
      "session_id" => ^session_id
    } = msg

    String.split(value)
    |> Enum.at(1)
    |> String.to_integer()
  end

  def create_response(
        %{"plugindata" => %{"data" => %{"audiobridge" => "created"}}} = msg,
        session_id,
        handle_id
      ) do
    %{
      "janus" => "success",
      "plugindata" => %{
        "data" => %{
          "audiobridge" => "created",
          "permanent" => false,
          "room" => room_id
        },
        "plugin" => "janus.plugin.audiobridge"
      },
      "sender" => ^handle_id,
      "session_id" => ^session_id
    } = msg

    room_id
  end

  def join(session_id, handle_id, room_id) do
    body = %{"request" => "join", "room" => room_id}
    msg = %{"body" => body}

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

  def participants(session_id, handle_id, room_id) do
    msg = %{"body" => %{"request" => "listparticipants", "room" => room_id}}

    Janus.send_message(@client, session_id, handle_id, msg)
  end

  def participants_response(session_id, handle_id, room_id, msg) do
    %{
      "janus" => "success",
      "plugindata" => %{
        "data" => %{
          "audiobridge" => "participants",
          "participants" => participants,
          "room" => ^room_id
        },
        "plugin" => "janus.plugin.audiobridge"
      },
      "sender" => ^handle_id,
      "session_id" => ^session_id,
      "transaction" => _
    } = msg

    participants
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

# Janus.send_message(@client, session_id, handle_id, %{
#   "body" => %{"request" => "listparticipants", "room" => Map.get(state, :room_id)}
# })
