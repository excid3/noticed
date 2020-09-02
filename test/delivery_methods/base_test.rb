require "test_helper"

class CustomDeliveryMethod < Noticed::DeliveryMethods::Base
  class_attribute :deliveries, default: []

  def deliver
    self.class.deliveries << params
  end
end

class CustomDeliveryMethodExample < Noticed::Base
  deliver_by :example, class: "CustomDeliveryMethod"
end

class Noticed::DeliveryMethods::BaseTest < ActiveSupport::TestCase
  test "Can use custom delivery method with params" do
    CustomDeliveryMethodExample.new.deliver(user)
    assert_equal 1, CustomDeliveryMethod.deliveries.count
  end
end
