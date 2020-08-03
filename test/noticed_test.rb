require "test_helper"

class Noticed::Test < ActiveSupport::TestCase
  test "stores data in params" do
    notification = make_notification(foo: :bar, user: user)
    assert_equal :bar, notification.params[:foo]
    assert_equal user, notification.params[:user]
  end

  test "can deliver a notification" do
    assert make_notification(foo: :bar).deliver(user)
  end

  test "enqueues notification jobs" do
    # Database delivery is not enqueued anymore
    assert_enqueued_jobs CommentNotification.delivery_methods.length - 1 do
      CommentNotification.new.deliver_later(user)
    end
  end

  test "cancels delivery when if clause is falsey" do
    class IfExample < Noticed::Base
      deliver_by :test, if: :falsey
      def falsey
        false
      end
    end

    IfExample.new.deliver(user)
    assert_empty Noticed::DeliveryMethods::Test.delivered
  end

  test "cancels delivery when unless clause is truthy" do
    class UnlessExample < Noticed::Base
      deliver_by :test, unless: :truthy
      def truthy
        true
      end
    end

    UnlessExample.new.deliver(user)
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

  test "runs callbacks on notifications" do
    class CallbackExample < Noticed::Base
      class_attribute :callbacks, default: []

      deliver_by :database

      after_deliver do
        self.class.callbacks << :everything
      end

      after_database do
        self.class.callbacks << :database
      end
    end

    CallbackExample.new.deliver(user)
    assert_equal [:database, :everything], CallbackExample.callbacks
  end

  test "runs callbacks on delivery methods" do
    assert_difference "Noticed::DeliveryMethods::Test.callbacks.count" do
      make_notification(foo: :bar).deliver(user)
    end
  end
end
