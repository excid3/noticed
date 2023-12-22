require "test_helper"

class DeliveryMethodTest < ActiveSupport::TestCase
  class InheritedDeliveryMethod < Noticed::DeliveryMethods::ActionCable
  end

  setup do
    @delivery_method = Noticed::DeliveryMethod.new
  end

  test "fetch_constant looks up constants" do
    set_config(
      mailer: "UserMailer"
    )
    assert_equal UserMailer, @delivery_method.fetch_constant(:mailer)
  end

  test "delivery methods inhiert required options" do
    assert_equal [:channel, :stream, :message], InheritedDeliveryMethod.required_option_names
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
