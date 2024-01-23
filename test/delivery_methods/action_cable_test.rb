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

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
