require "test_helper"

class CustomDeliveryMethod < Noticed::DeliveryMethods::Base
  def deliver
  end

  def self.validate!(options)
    unless options.key?(:a_required_option)
      raise Noticed::ValidationError, "the `a_required_option` attribute is missing"
    end
  end
end

class IfExample < Noticed::Base
  deliver_by :test, if: :falsey
  def falsey
    false
  end
end

class UnlessExample < Noticed::Base
  deliver_by :test, unless: :truthy
  def truthy
    true
  end
end

class IfRecipientExample < Noticed::Base
  deliver_by :test, if: :falsey
  def falsey
    raise ArgumentError unless recipient
  end
end

class UnlessRecipientExample < Noticed::Base
  deliver_by :test, unless: :truthy
  def truthy
    raise ArgumentError unless recipient
  end
end

class AttributeExample < Noticed::Base
  param :user_id
end

class MultipleParamsExample < Noticed::Base
  params :foo, :bar
end

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

class NotificationWithValidOptions < Noticed::Base
  deliver_by :custom, class: "Noticed::Test::CustomDeliveryMethod", a_required_option: true
end

class NotificationWithoutValidOptions < Noticed::Base
  deliver_by :custom, class: "Noticed::Test::CustomDeliveryMethod"
end

class Noticed::Test < ActiveSupport::TestCase
  test "stores data in params" do
    notification = make_notification(foo: :bar, user: user)
    assert_equal :bar, notification.params[:foo]
    assert_equal user, notification.params[:user]
  end

  test "can deliver a notification" do
    assert make_notification(foo: :bar).deliver(user)
  end

  test "enqueues notification jobs (skipping database)" do
    assert_enqueued_jobs CommentNotification.delivery_methods.length - 1 do
      CommentNotification.new.deliver_later(user)
    end
  end

  test "cancels delivery when if clause is falsey" do
    IfExample.new.deliver(user)
    assert_empty Noticed::DeliveryMethods::Test.delivered
  end

  test "cancels delivery when unless clause is truthy" do
    UnlessExample.new.deliver(user)
    assert_empty Noticed::DeliveryMethods::Test.delivered
  end

  test "has access to recipient in if clause" do
    assert_nothing_raised do
      IfRecipientExample.new.deliver(user)
    end
  end

  test "has access to recipient in unless clause" do
    assert_nothing_raised do
      UnlessRecipientExample.new.deliver(user)
    end
  end

  test "validates attributes for params" do
    assert_raises Noticed::ValidationError do
      AttributeExample.new.deliver(users(:one))
    end
  end

  test "allows to pass multiple params" do
    assert_equal [:foo, :bar], MultipleParamsExample.with(foo: true, bar: false).param_names
  end

  test "runs callbacks on notifications" do
    CallbackExample.new.deliver(user)
    assert_equal [:database, :everything], CallbackExample.callbacks
  end

  test "runs callbacks on delivery methods" do
    assert_difference "Noticed::DeliveryMethods::Test.callbacks.count" do
      make_notification(foo: :bar).deliver(user)
    end
  end

  test "can send notifications to multiple recipients" do
    assert User.count >= 2
    assert_difference "Notification.count", User.count do
      make_notification(foo: :bar).deliver(User.all)
    end
  end

  test "assigns record to notification when delivering" do
    make_notification(foo: :bar).deliver(user)
    assert_equal Notification.last, Noticed::DeliveryMethods::Test.delivered.last.record
  end

  test "assigns recipient to notification when delivering" do
    make_notification(foo: :bar).deliver(user)
    assert_equal user, Noticed::DeliveryMethods::Test.delivered.last.recipient
  end

  test "validates options of delivery methods when options are valid" do
    assert_nothing_raised do
      NotificationWithValidOptions.new.deliver(user)
    end
  end

  test "validates options of delivery methods when options are invalid" do
    assert_raises Noticed::ValidationError do
      NotificationWithoutValidOptions.new.deliver(user)
    end
  end
end
