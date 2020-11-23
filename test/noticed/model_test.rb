require "test_helper"

class ModelTest < ActiveSupport::TestCase
  test "can mark all notifications as read" do
    CommentNotification.with(foo: :bar).deliver(users(:one))
    Notification.mark_as_read!
    assert_not_nil Notification.last.read_at
  end
end
