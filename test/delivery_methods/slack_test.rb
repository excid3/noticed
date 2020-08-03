require "test_helper"

class SlackTest < ActiveSupport::TestCase
  class SlackExample < Noticed::Base
    deliver_by :slack
  end

  test "sends a POST to Slack" do
    Noticed::DeliveryMethods::Slack.any_instance.expects(:deliver)
    SlackExample.new.deliver(user)
  end
end
