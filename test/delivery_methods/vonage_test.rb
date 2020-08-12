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
    Noticed::DeliveryMethods::Vonage.any_instance.expects(:post)
    VonageExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    e = assert_raises(::Noticed::ResponseUnsuccessful) {
      VonageExample.new.deliver(user)
    }
    assert_equal HTTP::Response, e.response.class
  end
end
