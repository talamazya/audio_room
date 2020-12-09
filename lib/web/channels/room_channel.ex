defmodule Web.RoomChannel do
  @moduledoc """
  Mostly used to relay SDPs to janus, also handles some basic text chat functionality
  """
  use Web, :channel
  alias JanusEx.JanusChannel

  # def join("room:" <> room_name, _params, socket) do
  #   {:ok, pid} = JanusChannel.start_link(%{pid: self(), room_name: room_name})
  #   :ok = JanusChannel.create_session(pid)

  #   socket =
  #     socket
  #     |> assign(:room_name, room_name)
  #     |> assign(:janus_channel_pid, pid)

  #   {:ok, %{history: Room.list_messages(room_name)}, socket}
  # end

  def join("room:" <> room_name, _params, socket) do
    {:ok, pid} = JanusChannel.start_link(%{pid: self(), room_name: room_name})
    :ok = JanusChannel.create_session(pid)

    socket =
      socket
      |> assign(:room_name, room_name)
      |> assign(:janus_channel_pid, pid)

    {:ok, %{}, socket}
  end

  def handle_in("message:new", %{"content" => _content} = _params, socket) do
    # message = %Room.Message{author: username(params["name"]), content: content}
    # room_name = socket.assigns.room_name
    # :ok = Room.save_message(room_name, message)
    # broadcast!(socket, "message:new", %{"message" => message})

    # Web.Endpoint.broadcast!("rooms", "message:new", %{
    #   "room_name" => room_name,
    #   "message" => message
    # })

    # # I temporary list all participants here!
    # JanusChannel.participants(socket.assigns.janus_channel_pid)
    # |> IO.inspect(label: "rikiin list participant")

    {:reply, :ok, socket}
  end

  def handle_in("mute", %{"content" => participant_id}, socket) do
    JanusChannel.mute(socket.assigns.janus_channel_pid, participant_id)

    {:reply, :ok, socket}
  end

  def handle_in("candidate", candidate, socket) do
    :ok = JanusChannel.candidate(socket.assigns.janus_channel_pid, candidate)
    {:reply, :ok, socket}
  end

  def handle_in("offer", offer, socket) do
    :ok = JanusChannel.offer(socket.assigns.janus_channel_pid, offer)

    {:reply, :ok, socket}
  end

  def handle_info({:gimme_offer, _msg}, socket) do
    push(socket, "gimme_offer", %{})

    {:noreply, socket}
  end

  def handle_info({:answer, msg}, socket) do
    push(socket, "answer", msg)

    {:noreply, socket}
  end

  def handle_info({:participants, _participants}, socket) do
    {:noreply, socket}
  end

  def terminate({:shutdown, _} = reason, socket) do
    JanusChannel.leave_room(socket.assigns.janus_channel_pid)

    reason
  end

  def terminate(reason, _socket) do
    reason
  end

  # defp username(name) do
  #   default_username = "anonymous"

  #   if name do
  #     case String.trim(name) do
  #       "" -> default_username
  #       other -> other
  #     end
  #   else
  #     default_username
  #   end
  # end
end
