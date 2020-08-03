require "test_helper"

class VonageTest < ActiveSupport::TestCase
  class VonageExample < Noticed::Base
    deliver_by :vonage
  end

  test "sends a POST to Vonage" do
    Noticed::DeliveryMethods::Vonage.any_instance.expects(:deliver)
    VonageExample.new.deliver(user)
  end
end
