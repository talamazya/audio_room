defmodule RoomChannelTest do
  use Web.ChannelCase

  alias Web.RoomChannel
  alias Web.UserSocket

  setup do
    {:ok, _, socket} =
      UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(RoomChannel, "room:abc")

    {:ok, socket: socket}
  end

  describe "join a room" do
    test "happy path", %{socket: socket} do
      assert Map.get(socket.assigns, :janus_channel_pid) != nil
      assert Map.get(socket.assigns, :room_name) == "abc"
    end
  end

  describe "process webrtc handshake" do
    test "when process offer message", %{socket: socket} do
      ref = push(socket, "offer", %{})
      assert_reply(ref, :ok)
    end

    test "when process candidate message", %{socket: socket} do
      ref = push(socket, "candidate", %{})
      assert_reply(ref, :ok)
    end
  end
end
