defmodule JanusEx.Room do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # state = %{"room_1" => %{room_id: "xRy5", participants: [12Y, 6y7]}}
  def init(state) do
    {:ok, state}
  end

  def exist?(room_name) do
    GenServer.call(__MODULE__, {:exist, room_name})
  end

  def create(room_name, room_id) do
    GenServer.call(__MODULE__, {:create, room_name, room_id})
  end

  def participant(room_name, participant_id) do
    GenServer.call(__MODULE__, {:participant, room_name, participant_id})
  end

  def leave(room_name, room_id, participant_id) do
    GenServer.call(__MODULE__, {:leave, room_name, room_id, participant_id})
  end

  def handle_call({:exist, room_name}, _from, state) do
    res =
      Map.get(state, room_name)
      |> case do
        nil -> {false, janus_room_id(room_name)}
        %{room_id: room_id} -> {true, room_id}
      end

    {:reply, res, state}
  end

  def handle_call({:create, room_name, room_id}, _from, state) do
    state = Map.put(state, room_name, %{room_id: room_id, participants: []})
    {:reply, :ok, state}
  end

  def handle_call({:participant, room_name, participant_id}, _from, state) do
    %{participants: participants} = room = Map.get(state, room_name)
    room = Map.put(room, :participants, [participant_id | participants])

    {:reply, :ok, Map.put(state, room_name, room)}
  end

  def handle_call({:leave, room_name, _room_id, _participant_id} = msg, _from, state) do
    state =
      Map.get(state, room_name)
      |> leave_room(msg, state)

    {:reply, :ok, state}
  end

  defp janus_room_id(room_name) do
    :erlang.phash2(room_name)
  end

  defp leave_room(nil, _, state), do: state

  defp leave_room(
         %{participants: participants} = room,
         {:leave, room_name, _room_id, participant_id},
         state
       ) do
    if length(participants) <= 1 do
      # should be detroy room on Janus as well, but I dont have time now.
      # It will be done it later !!!!

      Map.delete(state, room_name)
    else
      room = Map.put(room, :participants, List.delete(participants, participant_id))
      Map.put(state, room_name, room)
    end
  end
end
