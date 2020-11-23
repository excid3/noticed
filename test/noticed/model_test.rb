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
    make_notification
    assert_equal 1, Notification.unread.count
  end

  test "read scope" do
    make_notification(read: true)
    assert_equal 1, Notification.read.count
  end

  def make_notification(read: false)
    CommentNotification.with(foo: :bar).deliver(users(:one))
    notification = Notification.last
    notification.mark_as_read! if read
    notification
  end
end
