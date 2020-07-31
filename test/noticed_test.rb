require "test_helper"

class Example < Noticed::Base
  deliver_by :test, foo: :bar
end

class Noticed::Test < ActiveSupport::TestCase
  test "stores data passed in" do
    assert_equal :bar, make_notification(foo: :bar).params[:foo]
  end

  test "stores objects in params" do
    assert_equal users(:one), make_notification(user: users(:one)).params[:user]
  end

  test "can deliver a notification" do
    assert make_notification(foo: :bar).deliver(users(:one))
  end

  test "can queue notification jobs" do
    assert_enqueued_jobs CommentNotification.delivery_methods.length do
      CommentNotification.new.deliver_later(users(:one))
    end
  end

  test "writes to database" do
    assert_difference "Notification.count" do
      CommentNotification.new.deliver(users(:one))
    end

    assert_equal 1, users(:one).notifications.count
  end

  test "sends email" do
    assert_enqueued_emails 1 do
      CommentNotification.new.deliver(users(:one))
    end
  end

  test "sends websocket message" do
    user = users(:one)
    channel = Noticed::NotificationChannel.broadcasting_for(user)
    assert_broadcasts(channel, 1) do
      CommentNotification.new.deliver(user)
    end
  end

  private

  def make_notification(params)
    Example.with(params)
  end
end
