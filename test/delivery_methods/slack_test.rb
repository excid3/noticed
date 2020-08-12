require "test_helper"

class SlackTest < ActiveSupport::TestCase
  class SlackExample < Noticed::Base
    deliver_by :slack, debug: true, url: :slack_url

    def slack_url
      "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
    end
  end

  test "sends a POST to Slack" do
    Noticed::DeliveryMethods::Slack.any_instance.expects(:post)
    SlackExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    e = assert_raises(::Noticed::ResponseUnsuccessful) {
      SlackExample.new.deliver(user)
    }
    assert_equal HTTP::Response, e.response.class
  end
end
