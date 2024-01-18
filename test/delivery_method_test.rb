require "test_helper"

class DeliveryMethodTest < ActiveSupport::TestCase
  class InheritedDeliveryMethod < Noticed::DeliveryMethods::ActionCable
  end

  test "fetch_constant looks up constants" do
    @delivery_method = Noticed::DeliveryMethod.new
    set_config(mailer: "UserMailer")
    assert_equal UserMailer, @delivery_method.fetch_constant(:mailer)
  end

  test "delivery methods inherit required options" do
    assert_equal [:message], InheritedDeliveryMethod.required_option_names
  end

  test "if config" do
    event = TestNotifier.deliver(User.first)
    notification = event.notifications.first
    @delivery_method = Noticed::DeliveryMethods::Test.new

    assert @delivery_method.perform(:test, notification, overrides: {if: true})
    assert @delivery_method.perform(:test, notification, overrides: {if: -> { unread? }})
    refute @delivery_method.perform(:test, notification, overrides: {if: false})
  end

  test "unless overrides" do
    event = TestNotifier.deliver(User.first)
    notification = event.notifications.first
    @delivery_method = Noticed::DeliveryMethods::Test.new

    refute @delivery_method.perform(:test, notification, overrides: {unless: true})
    assert @delivery_method.perform(:test, notification, overrides: {unless: false})
    assert @delivery_method.perform(:test, notification, overrides: {unless: -> { read? }})
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
