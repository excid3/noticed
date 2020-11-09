require "test_helper"

class VonageTest < ActiveSupport::TestCase
  setup do
    stub_request(:post, /rest.nexmo.com/).to_return(File.new(file_fixture("vonage.txt")))
  end

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
    VonageExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    without_webmock do
      e = assert_raises(::Noticed::ResponseUnsuccessful) {
        VonageExample.new.deliver(user)
      }
      assert_equal HTTP::Response, e.response.class
    end
  end

  test "deliver returns an http response" do
    args = {
      notification_class: "::VonageTest::VonageExample",
      recipient: user,
      options: {format: :to_vonage}
    }
    response = Noticed::DeliveryMethods::Vonage.new.perform(args)

    assert_kind_of HTTP::Response, response
  end
end
