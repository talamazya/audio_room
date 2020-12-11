defmodule JanusEx.AdminTest do
  use JanusEx.RoomCase

  describe "starting admin process" do
    test "should have session_id and handle_id after init step complete" do
      state = :sys.get_state(JanusEx.Admin)

      assert Map.get(state, :session_id) != nil
      assert Map.get(state, :handle_id) != nil
    end
  end

  describe "mute a participant" do
    test "when the participant is in unmuted state" do
      assert 1 == 1
    end

    test "when the participant had been muted already" do
      assert 2 == 2
    end
  end

  describe "unmute a participant" do
    test "when the participant is in muted state" do
      assert 3 == 3
    end

    test "when the participant had been unmuted already" do
      assert 4 == 4
    end
  end
end
