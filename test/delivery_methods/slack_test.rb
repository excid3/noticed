require "test_helper"

class SlackTest < ActiveSupport::TestCase
  setup do
    @delivery_method = Noticed::DeliveryMethods::Slack.new
    set_config(json: {foo: :bar})
  end

  test "sends a slack message" do
    stub_request(:post, Noticed::DeliveryMethods::Slack::DEFAULT_URL).with(body: "{\"foo\":\"bar\"}")
    assert_nothing_raised do
      @delivery_method.deliver
    end
  end

  test "raises error on failure" do
    stub_request(:post, Noticed::DeliveryMethods::Slack::DEFAULT_URL).to_return(status: 422)
    assert_raises Noticed::ResponseUnsuccessful do
      @delivery_method.deliver
    end
  end

  test "doesnt raise error on failed 200 status code request with raise_on_failure false" do
    @delivery_method.config[:raise_on_failure] = false
    stub_request(:post, Noticed::DeliveryMethods::Slack::DEFAULT_URL).with(body: "{\"foo\":\"bar\"}").to_return(status: 200, body: "{\"ok\": false}")
    assert_nothing_raised do
      @delivery_method.deliver
    end
  end

  test "raises error on 200 status code request with raise_on_failure true" do
    @delivery_method.config[:fail_on_error] = true
    stub_request(:post, Noticed::DeliveryMethods::Slack::DEFAULT_URL).with(body: "{\"foo\":\"bar\"}").to_return(status: 200, body: "{\"ok\": false}")
    assert_raises Noticed::ResponseUnsuccessful do
      @delivery_method.deliver
    end
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
