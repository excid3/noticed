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
    Noticed::DeliveryMethods::Vonage.any_instance.expects(:deliver)
    VonageExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    e = assert_raises(::Noticed::ResponseUnsuccessful) {
      VonageExample.new.deliver(user)
    }
    assert_equal HTTP::Response, e.response.class
  end

  test "deliver returns an http response" do
    Noticed::Base.any_instance.stubs(:vonage_format).returns({
      api_key: "a",
      api_secret: "b",
      from: "c",
      text: "d",
      to: "e",
      type: "unicode"
    })
    args = {
      notification_class: "Noticed::Base",
      recipient: user,
      options: {format: :vonage_format}
    }
    e = assert_raises(Noticed::ResponseUnsuccessful) {
      Noticed::DeliveryMethods::Vonage.new.perform(args)
    }

    assert_kind_of HTTP::Response, e.response
  end
end
