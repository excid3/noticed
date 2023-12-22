require "test_helper"

class Noticed::NotificationTest < ActiveSupport::TestCase
  test "delegates params to event" do
    notification = noticed_notifications(:one)
    assert_equal notification.event.params, notification.params
  end

  test "delegates record to event" do
    notification = noticed_notifications(:one)
    assert_equal notification.event.record, notification.record
  end

  test "notification associations" do
    assert_equal 1, users(:one).notifications.count
  end
end
