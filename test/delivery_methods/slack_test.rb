require "test_helper"

class SlackTest < ActiveSupport::TestCase
  setup do
    stub_request(:post, /hooks.slack.com/).to_return(File.new(file_fixture("slack.txt")))
  end

  class SlackExample < Noticed::Base
    deliver_by :slack, debug: true, url: :slack_url

    def slack_url
      "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
    end
  end

  test "sends a POST to Slack" do
    SlackExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    without_webmock do
      e = assert_raises(::Noticed::ResponseUnsuccessful) {
        SlackExample.new.deliver(user)
      }
      assert_equal HTTP::Response, e.response.class
    end
  end

  test "deliver returns an http response" do
    args = {
      notification_class: "::SlackTest::SlackExample",
      recipient: user,
      options: {url: :slack_url}
    }
    response = Noticed::DeliveryMethods::Slack.new.perform(args)

    assert_kind_of HTTP::Response, response
  end
end
