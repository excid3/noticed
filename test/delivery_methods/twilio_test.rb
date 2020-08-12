require "test_helper"

class TwilioTest < ActiveSupport::TestCase
  class TwilioExample < Noticed::Base
    deliver_by :twilio, credentials: :twilio_creds, debug: true # , ignore_failure: true

    def twilio_creds
      {
        account_sid: "a",
        auth_token: "b",
        phone_number: "c"
      }
    end
  end

  test "sends a POST to Twilio" do
    Noticed::DeliveryMethods::Twilio.any_instance.expects(:post)
    TwilioExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    e = assert_raises(::Noticed::ResponseUnsuccessful) {
      TwilioExample.new.deliver(user)
    }
    assert_equal HTTP::Response, e.response.class
  end
end
