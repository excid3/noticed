require "test_helper"

class CustomDeliveryMethod < Noticed::DeliveryMethods::Test
end

class CustomDeliveryMethodWithOptions < Noticed::DeliveryMethods::Test
  option :foo
end

class IndividualCustomDeliveryMethodExample < Noticed::Base
  deliver_by :example, class: "CustomDeliveryMethod"
end

class BulkDeliveryExample < Noticed::Base
  deliver_by :example, class: "CustomDeliveryMethod", bulk: {group_size: 2}
end

class WrongBulkDeliveryExample < Noticed::Base
  deliver_by :example, class: "CustomDeliveryMethod", bulk: {not_group_size: true}
end

class CustomDeliveryMethodWithOptionsExample < Noticed::Base
  deliver_by :example, class: "CustomDeliveryMethodWithOptions"
end

class DeliveryMethodWithNilOptionsExample < Noticed::Base
  deliver_by :example, class: "CustomDeliveryMethodWithOptions", foo: nil
end

class Noticed::DeliveryMethods::BaseTest < ActiveSupport::TestCase
  test "can perform individual deliveries" do
    IndividualCustomDeliveryMethodExample.new.deliver(user)
    assert_equal 1, CustomDeliveryMethod.individual_deliveries.count
    assert_equal 0, CustomDeliveryMethod.bulk_deliveries.count
  end

  test "can perform bulk deliveries" do
    assert_equal 3, User.count

    BulkDeliveryExample.new.deliver(User.all)
    assert_equal 0, CustomDeliveryMethod.individual_deliveries.count
    # For 3 users, with a group_size of 2, 2 batches of deliveries will be made.
    assert_equal 2, CustomDeliveryMethod.bulk_deliveries.count
  end

  test "validates `group_size` for bulk deliveries" do
    assert_raises Noticed::ValidationError do
      WrongBulkDeliveryExample.new.deliver(user)
    end
  end

  test "validates delivery method options" do
    assert_raises Noticed::ValidationError do
      CustomDeliveryMethodWithOptionsExample.new.deliver(user)
    end
  end

  test "nil options are valid" do
    assert_difference "Noticed::DeliveryMethods::Test.individual_deliveries.count" do
      DeliveryMethodWithNilOptionsExample.new.deliver(user)
    end
  end
end
