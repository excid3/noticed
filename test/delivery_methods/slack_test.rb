require "test_helper"

class SlackTest < ActiveSupport::TestCase
  class SlackExample < Noticed::Base
    deliver_by :slack, debug: true, url: :slack_url

    def slack_url
      "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
    end
  end

  test "sends a POST to Slack" do
    stub_delivery_method_request(delivery_method: :slack, matcher: /hooks.slack.com/)
    SlackExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    stub_delivery_method_request(delivery_method: :slack, matcher: /hooks.slack.com/, type: :failure)
    e = assert_raises(::Noticed::ResponseUnsuccessful) {
      SlackExample.new.deliver(user)
    }
    assert_equal HTTP::Response, e.response.class
  end

  test "deliver returns an http response" do
    stub_delivery_method_request(delivery_method: :slack, matcher: /hooks.slack.com/)

    args = {
      notification_class: "::SlackTest::SlackExample",
      recipient: user,
      options: {url: :slack_url}
    }
    response = Noticed::DeliveryMethods::Slack.new.perform(args)

    assert_kind_of HTTP::Response, response
  end

  test "logs verbosely in debug mode" do
    class ActiveSupport::Logger
      attr_reader :logging_log
      def debug(msg)
        @logging_log ||= []
        @logging_log << msg
      end
    end
    stub_delivery_method_request(delivery_method: :slack, matcher: /hooks.slack.com/)

    SlackExample.new.deliver(user)

    assert_equal Rails.logger.logging_log[-2..], [
      "POST https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX",
      "Response: 200: ok\r\n",
    ]
  end
end
