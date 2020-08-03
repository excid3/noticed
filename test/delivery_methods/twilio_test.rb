require "test_helper"

class TwilioTest < ActiveSupport::TestCase
  class TwilioExample < Noticed::Base
    deliver_by :twilio
  end

  test "sends a POST to Twilio" do
    Noticed::DeliveryMethods::Twilio.any_instance.expects(:deliver)
    TwilioExample.new.deliver(user)
  end
end
