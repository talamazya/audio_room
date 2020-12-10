defmodule JanusEx.JanusApi.Plugin.AudioBridge.Response do
  @plugin "janus.plugin.audiobridge"

  def from_session(msg, session_id, handle_id, janus \\ "success") do
    %{
      "janus" => ^janus,
      "plugindata" => %{
        "data" => data,
        "plugin" => @plugin
      },
      "sender" => ^handle_id,
      "session_id" => ^session_id,
      "transaction" => _
    } = msg

    data
  end

  def from_room_existed(msg) do
    %{
      "audiobridge" => "event",
      # "error" => "Room 112114386 already exists"
      "error" => value,
      "error_code" => 486
    } = msg

    value
  end

  def from_room_create_successfully(msg) do
    %{
      "audiobridge" => "created",
      "permanent" => false,
      "room" => room_id
    } = msg

    room_id
  end

  def from_participants(msg, room_id) do
    %{
      "audiobridge" => "participants",
      "participants" => participants,
      "room" => ^room_id
    } = msg

    participants
  end

  def from_join(msg) do
    %{
      "audiobridge" => "joined",
      "id" => participant_id,
      "participants" => _,
      "room" => room_id
    } = msg

    {participant_id, room_id}
  end

  def from_mute(%{"audiobridge" => "success", "room" => room_id}, room_id), do: {:ok, :success}
  def from_mute(%{"audiobridge" => "success"}, _), do: {:ok, :already_muted}
  def from_mute(data, _), do: {:error, data}

  def from_attach(msg, session_id) do
    %{
      "janus" => "success",
      "session_id" => ^session_id,
      "data" => %{"id" => handle_id}
    } = msg

    handle_id
  end
end
