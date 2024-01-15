require "test_helper"

class SlackTest < ActiveSupport::TestCase
  setup do
    @delivery_method = Noticed::DeliveryMethods::Slack.new
    set_config(json: {foo: :bar})
  end

  test "sends a slack message" do
    stub_request(:post, Noticed::DeliveryMethods::Slack::DEFAULT_URL).with(body: "{\"foo\":\"bar\"}")
    @delivery_method.deliver
  end

  test "raises error on failure" do
    stub_request(:post, Noticed::DeliveryMethods::Slack::DEFAULT_URL).to_return(status: 422)
    assert_raises Noticed::ResponseUnsuccessful do
      @delivery_method.deliver
    end
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
