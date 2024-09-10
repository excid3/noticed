require "test_helper"

class DeliveryMethodTest < ActiveSupport::TestCase
  class InheritedDeliveryMethod < Noticed::DeliveryMethods::ActionCable
  end

  test "fetch_constant looks up constants from String" do
    @delivery_method = Noticed::DeliveryMethod.new
    set_config(mailer: "UserMailer")
    assert_equal UserMailer, @delivery_method.fetch_constant(:mailer)
  end

  test "fetch_constant looks up constants from proc that returns String" do
    @delivery_method = Noticed::DeliveryMethod.new
    set_config(mailer: -> { "UserMailer" })
    assert_equal UserMailer, @delivery_method.fetch_constant(:mailer)
  end

  test "delivery methods inherit required options" do
    assert_equal [:message], InheritedDeliveryMethod.required_option_names
  end

  test "if config" do
    event = TestNotifier.deliver(User.first)
    notification = event.notifications.first
    delivery_method = Noticed::DeliveryMethods::Test.new

    assert delivery_method.perform(:test, notification, overrides: {if: true})
    assert delivery_method.perform(:test, notification, overrides: {if: -> { unread? }})
    refute delivery_method.perform(:test, notification, overrides: {if: false})
  end

  test "unless overrides" do
    event = TestNotifier.deliver(User.first)
    notification = event.notifications.first
    delivery_method = Noticed::DeliveryMethods::Test.new

    refute delivery_method.perform(:test, notification, overrides: {unless: true})
    assert delivery_method.perform(:test, notification, overrides: {unless: false})
    assert delivery_method.perform(:test, notification, overrides: {unless: -> { read? }})
  end

  test "passes notification when calling methods on Event" do
    notification = noticed_notifications(:one)
    event = notification.event

    def event.example_method(notification)
      @example = notification
    end

    delivery_method = Noticed::DeliveryMethods::Test.new
    delivery_method.instance_variable_set :@notification, notification
    delivery_method.instance_variable_set :@event, event
    delivery_method.instance_variable_set :@config, {if: :example_method}
    delivery_method.evaluate_option(:if)

    assert_equal notification, event.instance_variable_get(:@example)
  end

  class CallbackDeliveryMethod < Noticed::DeliveryMethod
    before_deliver :set_message
    attr_reader :message

    def set_message
      @message = "new message"
    end

    def deliver
    end
  end

  class CallbackBulkDeliveryMethod < Noticed::BulkDeliveryMethod
    before_deliver :set_message
    attr_reader :message

    def set_message
      @message = "new message"
    end

    def deliver
    end
  end

  class CallbackNotifier < Noticed::Event
    deliver_by :test
  end

  class CallbackBulkNotifier < Noticed::Event
    bulk_deliver_by :test
  end

  test "calls callbacks" do
    event = CallbackNotifier.with(message: "test")
    notification = Noticed::Notification.create(recipient: User.first, event: event)
    delivery_method = CallbackDeliveryMethod.new
    delivery_method.perform(:test, notification)
    assert_equal delivery_method.message, "new message"
  end

  test "calls callbacks for bulk delivery" do
    event = CallbackBulkNotifier.with(message: "test")
    delivery_method = CallbackBulkDeliveryMethod.new
    delivery_method.perform(:test, event)
    assert_equal delivery_method.message, "new message"
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
