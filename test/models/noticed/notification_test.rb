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

  test "read scope" do
    assert_equal 4, Noticed::Notification.read.count
  end

  test "unread scope" do
    assert_equal 0, Noticed::Notification.unread.count
  end

  test "seen scope" do
    assert_equal 4, Noticed::Notification.seen.count
  end

  test "unseen scope" do
    assert_equal 0, Noticed::Notification.unseen.count
  end

  test "mark_as_read" do
    Noticed::Notification.update_all(read_at: nil)
    assert_equal 0, Noticed::Notification.read.count
    Noticed::Notification.mark_as_read
    assert_equal 4, Noticed::Notification.read.count
  end

  test "mark_as_unread" do
    Noticed::Notification.update_all(read_at: Time.current)
    assert_equal 4, Noticed::Notification.read.count
    Noticed::Notification.mark_as_unread
    assert_equal 0, Noticed::Notification.read.count
  end

  test "mark_as_seen" do
    Noticed::Notification.update_all(seen_at: nil)
    assert_equal 0, Noticed::Notification.seen.count
    Noticed::Notification.mark_as_seen
    assert_equal 4, Noticed::Notification.seen.count
  end

  test "mark_as_unseen" do
    Noticed::Notification.update_all(seen_at: Time.current)
    assert_equal 4, Noticed::Notification.seen.count
    Noticed::Notification.mark_as_unseen
    assert_equal 0, Noticed::Notification.seen.count
  end

  test "read?" do
    assert noticed_notifications(:one).read?
  end

  test "unread?" do
    assert_not noticed_notifications(:one).unread?
  end

  test "seen?" do
    assert noticed_notifications(:one).seen?
  end

  test "unseen?" do
    assert_not noticed_notifications(:one).unseen?
  end

  test "notification url helpers" do
    assert_equal "http://localhost:3000/", CommentNotifier::Notification.new.root_url
  end

  test "ephemeral notification url helpers" do
    assert_equal "http://localhost:3000/", EphemeralNotifier::Notification.new.root_url
  end
end
