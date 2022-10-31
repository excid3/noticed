require "test_helper"

class SlackMessageTest < ActiveSupport::TestCase
  class SlackMessageExample < Noticed::Base
    deliver_by :slack_message, debug: true

    def slack_token
      "fake-slack-token"
    end

    def slack_channel
      "fake-slack-id"
    end
  end

  test "sends a POST to Slack API" do
    stub_delivery_method_request(delivery_method: :slack_message, matcher: /slack.com\/api\/chat.postMessage/)
    SlackMessageExample.with(text: "Hello World").deliver(user)
  end

  test "raises an error when http request fails" do
    stub_delivery_method_request(delivery_method: :slack_message, matcher: /slack.com\/api\/chat.postMessage/, type: :failure)
    e = assert_raises(::Noticed::ResponseUnsuccessful) {
      SlackMessageExample.with(text: "Hello World").deliver(user)
    }
    assert_kind_of String, e.response
    assert_equal "too_many_attachments", e.response
  end

  test "deliver returns an http response" do
    stub_delivery_method_request(delivery_method: :slack_message, matcher: /slack.com\/api\/chat.postMessage/)

    args = {
      notification_class: "::SlackMessageTest::SlackMessageExample",
      recipient: user,
      options: {text: "Hello"}
    }
    response = Noticed::DeliveryMethods::SlackMessage.new.perform(args)

    assert_kind_of Net::HTTPOK, response
  end
end
