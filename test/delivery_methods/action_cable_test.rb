require "test_helper"

class FakeChannel < ApplicationCable::Channel
end

class FakeChannelNotification < Noticed::Base
  deliver_by :action_cable, channel: :get_channel

  def get_channel
    FakeChannel
  end
end

class ActionCableTest < ActiveSupport::TestCase
  test "sends websocket message" do
    channel = Noticed::NotificationChannel.broadcasting_for(user)
    assert_broadcasts(channel, 1) do
      CommentNotification.new.deliver(user)
    end
  end

  test "accepts channel as string" do
    delivery_method = Noticed::DeliveryMethods::ActionCable.new
    delivery_method.instance_variable_set(:@options, {channel: "FakeChannel"})
    assert_equal FakeChannel, delivery_method.send(:channel)
  end

  test "accepts channel as object" do
    delivery_method = Noticed::DeliveryMethods::ActionCable.new
    delivery_method.instance_variable_set(:@options, {channel: FakeChannel})
    assert_equal FakeChannel, delivery_method.send(:channel)
  end

  test "accepts channel as symbol" do
    delivery_method = Noticed::DeliveryMethods::ActionCable.new
    delivery_method.instance_variable_set(:@notification, FakeChannelNotification.new)
    delivery_method.instance_variable_set(:@options, {channel: :get_channel})
    assert_equal FakeChannel, delivery_method.send(:channel)
  end

  test "deliver returns nothing" do
    args = {
      notification_class: "Noticed::Base",
      recipient: user,
      options: {}
    }
    nothing = Noticed::DeliveryMethods::ActionCable.new.perform(args)

    assert_nil nothing
  end
end
