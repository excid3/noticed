require "test_helper"

class ActionCableDeliveryMethodTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @delivery_method = Noticed::DeliveryMethods::ActionCable.new
  end

  test "sends websocket message" do
    user = users(:one)
    channel = Noticed::NotificationChannel.broadcasting_for(user)

    set_config(
      channel: "Noticed::NotificationChannel",
      stream: user,
      message: {foo: :bar}
    )

    assert_broadcasts(channel, 1) do
      @delivery_method.deliver
    end
  end

  test "default channel" do
    set_config({})
    assert_equal Noticed::NotificationChannel, @delivery_method.channel
  end

  test "default stream" do
    notification = noticed_notifications(:one)
    set_config({})
    @delivery_method.instance_variable_set :@notification, notification
    assert_equal notification.recipient, @delivery_method.stream
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::OrderedOptions.new.merge(config)
  end
end
