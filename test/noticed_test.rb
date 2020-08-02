require "test_helper"

class Example < Noticed::Base
  deliver_by :test, foo: :bar
  deliver_by :database
end

class Noticed::Test < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "stores data passed in" do
    assert_equal :bar, make_notification(foo: :bar).params[:foo]
  end

  test "stores objects in params" do
    assert_equal @user, make_notification(user: @user).params[:user]
  end

  test "can deliver a notification" do
    assert make_notification(foo: :bar).deliver(@user)
  end

  test "enqueues notification jobs" do
    # Database delivery is not enqueued anymore
    assert_enqueued_jobs CommentNotification.delivery_methods.length - 1 do
      CommentNotification.new.deliver_later(@user)
    end
  end

  test "writes to the database before other delivery moethods" do
    Example.with(foo: :bar).deliver_later(@user)
    perform_enqueued_jobs
    assert_not_nil Notification.last
    assert_equal Notification.last, Noticed::DeliveryMethods::Test.delivered.first.record
  end

  test "writes to database" do
    notification = CommentNotification.with(foo: :bar)

    assert_difference "Notification.count" do
      notification.deliver(@user)
    end

    assert_equal 1, @user.notifications.count
    assert_equal "bar", @user.notifications.last.params["foo"]
  end

  test "writes to custom params database" do
    CommentNotification.with(foo: :bar).deliver(@user)
    assert_equal 1, @user.notifications.first.account_id
  end

  test "sends email" do
    assert_enqueued_emails 1 do
      CommentNotification.new.deliver(@user)
    end
  end

  test "sends websocket message" do
    user = @user
    channel = Noticed::NotificationChannel.broadcasting_for(user)
    assert_broadcasts(channel, 1) do
      CommentNotification.new.deliver(user)
    end
  end

  test "cancels delivery when if clause is falsey" do
    class IfExample < Noticed::Base
      deliver_by :test, if: :falsey

      def falsey
        false
      end
    end

    IfExample.new.deliver(@user)
    assert_empty Noticed::DeliveryMethods::Test.delivered
  end

  test "cancels delivery when unless clause is truthy" do
    class UnlessExample < Noticed::Base
      deliver_by :test, unless: :truthy

      def truthy
        true
      end
    end

    UnlessExample.new.deliver(@user)
    assert_empty Noticed::DeliveryMethods::Test.delivered
  end

  test "validates attributes for params" do
    class AttributeExample < Noticed::Base
      param :user_id
    end

    assert_raises Noticed::ValidationError do
      AttributeExample.new.deliver(users(:one))
    end
  end

  private

  def make_notification(params)
    Example.with(params)
  end
end
