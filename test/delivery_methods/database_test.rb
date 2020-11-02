require "test_helper"

class DatabaseTest < ActiveSupport::TestCase
  test "writes to database" do
    notification = CommentNotification.with(foo: :bar)

    assert_difference "Notification.count" do
      notification.deliver(user)
    end

    assert_equal 1, user.notifications.count
    assert_equal :bar, user.notifications.last.params[:foo]
  end

  test "writes to custom params database" do
    CommentNotification.with(foo: :bar).deliver(user)
    assert_equal 1, user.notifications.first.account_id
  end

  test "writes to the database before other delivery methods" do
    CommentNotification.with(foo: :bar).deliver_later(user)
    perform_enqueued_jobs
    assert_not_nil Notification.last
    assert_equal Notification.last, Noticed::DeliveryMethods::Test.delivered.first.record
  end

  test "serializes database attributes like ActiveJob does" do
    assert_difference "Notification.count" do
      CommentNotification.with(user: user).deliver(user)
    end
    assert_equal @user, Notification.last.params[:user]
  end

  test "deliver returns the created record" do
    args = {
      notification_class: "Noticed::Base",
      recipient: user,
      options: {}
    }
    record = Noticed::DeliveryMethods::Database.new.perform(args)

    assert_kind_of ActiveRecord::Base, record
  end
end
