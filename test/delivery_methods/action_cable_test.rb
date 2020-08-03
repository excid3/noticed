require "test_helper"

class ActionCableTest < ActiveSupport::TestCase
  test "sends websocket message" do
    channel = Noticed::NotificationChannel.broadcasting_for(user)
    assert_broadcasts(channel, 1) do
      CommentNotification.new.deliver(user)
    end
  end
end
