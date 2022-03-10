require "test_helper"

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

class RecipientExample < Noticed::Base
  deliver_by :database

  def message
    recipient.id
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

  before_database do
    raise ArgumentError unless recipient

    self.class.callbacks << :before_database
  end

  around_database do
    raise ArgumentError unless recipient

    self.class.callbacks << :around_database
  end

  after_database do
    raise ArgumentError unless recipient

    self.class.callbacks << :after_database
  end

  after_deliver do
    self.class.callbacks << :after_everything
  end
end

class RequiredOption < Noticed::DeliveryMethods::Base
  def deliver
  end

  def self.validate!(options)
    unless options.key?(:a_required_option)
      raise Noticed::ValidationError, "the `a_required_option` attribute is missing"
    end
  end
end

class NotificationWithValidOptions < Noticed::Base
  deliver_by :custom, class: "RequiredOption", a_required_option: true
end

class NotificationWithoutValidOptions < Noticed::Base
  deliver_by :custom, class: "RequiredOption"
end

class With5MinutesDelay < Noticed::Base
  deliver_by :test, delay: 5.minutes
end

class WithDynamicDelay < Noticed::Base
  deliver_by :test, delay: :dynamic_delay

  def dynamic_delay
    recipient.email == "first@example.com" ? 1.minute : 2.minutes
  end
end

class WithCustomQueue < Noticed::Base
  deliver_by :test, queue: "custom"
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
      CommentNotification.deliver_later(user)
    end
  end

  test "cancels delivery when if clause is falsey" do
    IfExample.deliver(user)
    assert_empty Noticed::DeliveryMethods::Test.delivered
  end

  test "cancels delivery when unless clause is truthy" do
    UnlessExample.deliver(user)
    assert_empty Noticed::DeliveryMethods::Test.delivered
  end

  test "has access to recipient in if clause" do
    assert_nothing_raised do
      IfRecipientExample.deliver(user)
    end
  end

  test "has access to recipient in unless clause" do
    assert_nothing_raised do
      UnlessRecipientExample.deliver(user)
    end
  end

  test "has access to recipient in notification instance" do
    RecipientExample.deliver(user)
    assert_equal user.id, Notification.last.to_notification.message
  end

  test "validates attributes for params" do
    assert_raises Noticed::ValidationError do
      AttributeExample.deliver(users(:one))
    end
  end

  test "allows to pass multiple params" do
    assert_equal [:foo, :bar], MultipleParamsExample.with(foo: true, bar: false).param_names
  end

  test "runs callbacks on notifications" do
    CallbackExample.deliver(user)
    assert_equal [:before_database, :around_database, :after_database, :after_everything], CallbackExample.callbacks
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
    notification = make_notification(foo: :bar)
    notification.deliver(user)
    assert_equal Notification.last, Noticed::DeliveryMethods::Test.delivered.last.record
    assert_equal notification.record, Noticed::DeliveryMethods::Test.delivered.last.record
  end

  test "assigns recipient to notification when delivering" do
    make_notification(foo: :bar).deliver(user)
    assert_equal user, Noticed::DeliveryMethods::Test.delivered.last.recipient
  end

  test "validates options of delivery methods when options are valid" do
    assert_nothing_raised do
      NotificationWithValidOptions.deliver(user)
    end
  end

  test "validates options of delivery methods when options are invalid" do
    assert_raises Noticed::ValidationError do
      NotificationWithoutValidOptions.deliver(user)
    end
  end

  test "asserts delivery is delayed" do
    freeze_time do
      assert_enqueued_with(at: 5.minutes.from_now) do
        With5MinutesDelay.deliver(user)
      end
    end
  end

  test "asserts dynamic delay" do
    freeze_time do
      assert_enqueued_with(at: 1.minutes.from_now) do
        WithDynamicDelay.deliver(users(:one))
      end

      assert_enqueued_with(at: 2.minutes.from_now) do
        WithDynamicDelay.deliver(users(:two))
      end
    end
  end

  test "asserts delivery is queued with different queue" do
    assert_enqueued_with(queue: "custom") do
      WithCustomQueue.deliver_later(user)
    end
  end

  test "loading notification from fixture" do
    notification = notifications(:one)
    assert_equal accounts(:primary), notification.params[:account]
  end
end
