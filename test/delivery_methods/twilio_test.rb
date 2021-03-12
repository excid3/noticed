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
    stub_delivery_method_request(delivery_method: :twilio, matcher: /api.twilio.com/)
    TwilioExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    stub_delivery_method_request(delivery_method: :twilio, matcher: /api.twilio.com/, type: :failure)
    e = assert_raises(::Noticed::ResponseUnsuccessful) {
      TwilioExample.new.deliver(user)
    }
    assert_equal HTTP::Response, e.response.class
  end

  test "deliver returns an http response" do
    stub_delivery_method_request(delivery_method: :twilio, matcher: /api.twilio.com/)

    args = {
      notifier_class: "::TwilioTest::TwilioExample",
      recipient: user,
      options: {credentials: :twilio_creds}
    }
    response = Noticed::DeliveryMethods::Twilio.new.perform(args)

    assert_kind_of HTTP::Response, response
  end
end
