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

class DeliveryMethodWithOptions < Noticed::DeliveryMethods::Test
  option :foo
end

class DeliveryMethodWithOptionsExample < Noticed::Base
  deliver_by :example, class: "DeliveryMethodWithOptions"
end

class Noticed::DeliveryMethods::BaseTest < ActiveSupport::TestCase
  test "Can use custom delivery method with params" do
    CustomDeliveryMethodExample.new.deliver(user)
    assert_equal 1, CustomDeliveryMethod.deliveries.count
  end

  test "validates delivery method options" do
    assert_raises Noticed::ValidationError do
      DeliveryMethodWithOptionsExample.new.deliver(user)
    end
  end

  test "nil options are valid" do
    class DeliveryMethodWithNilOptionsExample < Noticed::Base
      deliver_by :example, class: "DeliveryMethodWithOptions", foo: nil
    end

    assert_difference "Noticed::DeliveryMethods::Test.delivered.count" do
      DeliveryMethodWithNilOptionsExample.new.deliver(user)
    end
  end
end
