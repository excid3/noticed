require "test_helper"

class WebhookTest < ActiveSupport::TestCase
  class WebhookExampleWithoutWebhookUrl < Noticed::Base
    deliver_by :webhook, debug: true
  end

  class WebhookExample < Noticed::Base
    deliver_by :webhook, debug: true, url: :webhook_url

    def webhook_url
      "https://webhook.site/8c6ed375-d871-41b9-9536-e01b47d6b20b"
    end
  end

  test "sends a POST to Webhook link" do
    stub_delivery_method_request(delivery_method: :webhook, matcher: /webhook.site/)
    WebhookExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    stub_delivery_method_request(delivery_method: :webhook, matcher: /webhook.site/, type: :failure)
    e = assert_raises(::Noticed::ResponseUnsuccessful) {
      WebhookExample.new.deliver(user)
    }
    assert_equal HTTP::Response, e.response.class
  end

  test "deliver returns an http response" do
    stub_delivery_method_request(delivery_method: :webhook, matcher: /webhook.site/)

    args = {
      notification_class: "::WebhookTest::WebhookExample",
      recipient: user,
      options: {url: :webhook_url}
    }
    response = Noticed::DeliveryMethods::Webhook.new.perform(args)

    assert_kind_of HTTP::Response, response
  end

  test "validates webhook url is specified for webhook delivery method" do
    assert_raises Noticed::ValidationError do
      WebhookExampleWithoutWebhookUrl.new.deliver(user)
    end
  end
end
