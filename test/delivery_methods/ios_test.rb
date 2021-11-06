require "test_helper"

class IosExample < Noticed::Base
  deliver_by :ios

  def ios_device_tokens(recipient)
    []
  end
end

class IosExampleWithoutDeviceTokens < Noticed::Base
  deliver_by :ios
end

class IosTest < ActiveSupport::TestCase
  test "raises error when bundle_identifier missing" do
    exception = assert_raises ArgumentError do
      Noticed::DeliveryMethods::Ios.new.perform(notification_class: "IosExample")
    end

    assert_equal "bundle_identifier is missing", exception.message
  end

  test "raises error when key_id missing" do
    exception = assert_raises ArgumentError do
      Noticed::DeliveryMethods::Ios.new.perform(
        notification_class: "IosExample",
        options: {
          bundle_identifier: "test"
        }
      )
    end

    assert_equal "key_id is missing", exception.message
  end

  test "raises error when team_id missing" do
    exception = assert_raises ArgumentError do
      Noticed::DeliveryMethods::Ios.new.perform(
        notification_class: "IosExample",
        options: {
          bundle_identifier: "test",
          key_id: "test"
        }
      )
    end

    assert_equal "team_id is missing", exception.message
  end

  test "raises error when cert missing" do
    exception = assert_raises ArgumentError do
      Noticed::DeliveryMethods::Ios.new.perform(
        notification_class: "IosExample",
        options: {
          bundle_identifier: "test",
          key_id: "test",
          team_id: "test"
        }
      )
    end

    assert_match "Could not find APN cert at", exception.message
  end

  test "raises error when ios_device_tokens method is missing" do
    assert_raises NoMethodError do
      File.stub :exist?, true do
        Noticed::DeliveryMethods::Ios.new.perform(
          notification_class: "IosExampleWithoutDeviceTokens",
          options: {
            bundle_identifier: "test",
            key_id: "test",
            team_id: "test"
          }
        )
      end
    end
  end
end
