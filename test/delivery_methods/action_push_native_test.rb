require "test_helper"

class ActionPushNativeTest < ActiveSupport::TestCase
  # Mimics the ActionPushNative::Notification builder API
  class FakePushNotification
    class_attribute :deliveries, default: []

    class Builder
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def with_apple(value)
        tap { options[:apple] = value }
      end

      def with_google(value)
        tap { options[:google] = value }
      end

      def with_data(value)
        tap { options[:data] = value }
      end

      def new(**attributes)
        FakePushNotification.new(options, attributes)
      end
    end

    def self.silent
      Builder.new(silent: true)
    end

    def self.with_apple(value)
      Builder.new.with_apple(value)
    end

    attr_reader :options, :attributes, :devices

    def initialize(options, attributes)
      @options, @attributes = options, attributes
    end

    def deliver_later_to(devices)
      @devices = devices
      deliveries << self
    end
  end

  setup do
    FakePushNotification.deliveries = []
    @delivery_method = Noticed::DeliveryMethods::ActionPushNative.new
    @delivery_method.instance_variable_set :@notification, noticed_notifications(:one)
  end

  test "delivers to devices with format and platform options" do
    set_config(
      notification_class: "ActionPushNativeTest::FakePushNotification",
      devices: [:device],
      format: {title: "Hello", body: "World"},
      with_apple: {category: "observable"},
      with_google: {priority: "high"},
      with_data: {url: "/"}
    )

    @delivery_method.deliver

    delivery = FakePushNotification.deliveries.sole
    assert_equal [:device], delivery.devices
    assert_equal({title: "Hello", body: "World"}, delivery.attributes)
    assert_equal({apple: {category: "observable"}, google: {priority: "high"}, data: {url: "/"}}, delivery.options)
  end

  test "silent notifications" do
    set_config(
      notification_class: "ActionPushNativeTest::FakePushNotification",
      devices: [:device],
      format: {title: "Hello"},
      silent: true
    )

    @delivery_method.deliver

    assert FakePushNotification.deliveries.sole.options[:silent]
  end

  test "notification_class can be evaluated from a lambda" do
    set_config(
      notification_class: -> { ActionPushNativeTest::FakePushNotification },
      devices: [:device],
      format: {title: "Hello"}
    )

    assert_difference "FakePushNotification.deliveries.size" do
      @delivery_method.deliver
    end
  end

  private

  def set_config(config)
    # Real config is OrderedOptions, which leaves nested hashes alone (HashWithIndifferentAccess would stringify their keys)
    @delivery_method.instance_variable_set :@config, ActiveSupport::OrderedOptions.new.merge(config)
  end
end
