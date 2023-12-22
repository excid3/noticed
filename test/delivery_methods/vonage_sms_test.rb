require "test_helper"

class VonageSmsTest < ActiveSupport::TestCase
  setup do
    @delivery_method = Noticed::DeliveryMethods::VonageSms.new
  end

  test "sends sms" do
    set_config(json: {foo: :bar})
    stub_request(:post, Noticed::DeliveryMethods::VonageSms::DEFAULT_URL).with(body: "{\"foo\":\"bar\"}").to_return(status: 200, body: "{\"messages\":[{\"status\":\"0\"}]}")
    @delivery_method.deliver
  end

  test "raises error on failure" do
    set_config(json: {foo: :bar})
    stub_request(:post, Noticed::DeliveryMethods::VonageSms::DEFAULT_URL).to_return(status: 200, body: "{\"messages\":[{\"status\":\"1\"}]}")
    assert_raises Noticed::ResponseUnsuccessful do
      @delivery_method.deliver
    end
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
