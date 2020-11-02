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

  test "deliver returns an http response" do
    Noticed::Base.any_instance.stubs(:slack_url).returns("https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX")
    args = {
      notification_class: "Noticed::Base",
      recipient: user,
      options: {url: :slack_url}
    }
    e = assert_raises(Noticed::ResponseUnsuccessful) {
      Noticed::DeliveryMethods::Slack.new.perform(args)
    }

    assert_kind_of HTTP::Response, e.response
  end
end
