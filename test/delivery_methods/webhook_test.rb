require "test_helper"

class WebhookDeliveryMethodTest < ActiveSupport::TestCase
  setup do
    @delivery_method = Noticed::DeliveryMethods::Webhook.new
  end

  test "webhook with json payload" do
    set_config(
      url: "https://example.org/webhook",
      json: {foo: :bar}
    )
    stub_request(:post, "https://example.org/webhook").with(body: "{\"foo\":\"bar\"}")

    @delivery_method.deliver
  end

  test "webhook with form payload" do
    set_config(
      url: "https://example.org/webhook",
      form: {foo: :bar}
    )
    stub_request(:post, "https://example.org/webhook").with(headers: {"Content-Type" => /application\/x-www-form-urlencoded/})
    @delivery_method.deliver
  end

  test "webhook with basic auth" do
    set_config(
      url: "https://example.org/webhook",
      basic_auth: {user: "username", pass: "password"}
    )
    stub_request(:post, "https://example.org/webhook").with(headers: {"Authorization" => "Basic dXNlcm5hbWU6cGFzc3dvcmQ="})
    @delivery_method.deliver
  end

  test "webhook with headers" do
    set_config(
      url: "https://example.org/webhook",
      headers: {"Content-Type" => "application/json"}
    )
    stub_request(:post, "https://example.org/webhook").with(headers: {"Content-Type" => "application/json"})
    @delivery_method.deliver
  end

  test "webhook raises error with unsuccessful status codes" do
    set_config(url: "https://example.org/webhook")
    stub_request(:post, "https://example.org/webhook").to_return(status: 422)
    assert_raises Noticed::ResponseUnsuccessful do
      @delivery_method.deliver
    end
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
