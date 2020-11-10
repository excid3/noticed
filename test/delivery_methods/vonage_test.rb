require "test_helper"

class VonageTest < ActiveSupport::TestCase
  class VonageExample < Noticed::Base
    deliver_by :vonage, format: :to_vonage, debug: true

    def to_vonage
      {
        api_key: "a",
        api_secret: "b",
        from: "c",
        text: "d",
        to: "e",
        type: "unicode"
      }
    end
  end

  test "sends a POST to Vonage" do
    stub_delivery_method_request(delivery_method: :vonage, matcher: /rest.nexmo.com/)
    VonageExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    stub_delivery_method_request(delivery_method: :vonage, matcher: /rest.nexmo.com/, type: :failure)
    e = assert_raises(::Noticed::ResponseUnsuccessful) {
      VonageExample.new.deliver(user)
    }
    assert_equal HTTP::Response, e.response.class
  end

  test "deliver returns an http response" do
    stub_delivery_method_request(delivery_method: :vonage, matcher: /rest.nexmo.com/)

    args = {
      notification_class: "::VonageTest::VonageExample",
      recipient: user,
      options: {format: :to_vonage}
    }
    response = Noticed::DeliveryMethods::Vonage.new.perform(args)

    assert_kind_of HTTP::Response, response
  end
end
