require "test_helper"

class ModelTest < ActiveSupport::TestCase
  test "can mark notifications as read" do
    notification = make_notification
    Notification.mark_as_read!
    assert_not_nil notification.reload.read_at
  end

  test "can mark notifications as unread" do
    notification = make_notification(read: true)
    Notification.mark_as_unread!
    assert_nil notification.reload.read_at
  end

  test "unread scope" do
    assert_difference "Notification.unread.count" do
      make_notification
    end
  end

  test "read scope" do
    assert_difference "Notification.read.count" do
      make_notification(read: true)
    end
  end

  def make_notification(read: false)
    CommentNotification.with(foo: :bar).deliver(users(:one))
    notification = Notification.last
    notification.mark_as_read! if read
    notification
  end
end
