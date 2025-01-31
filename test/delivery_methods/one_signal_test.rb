require "test_helper"

class OneSignalTest < ActiveSupport::TestCase
  setup do
    @delivery_method = Noticed::DeliveryMethods::OneSignal.new
    @config = {
      app_id: "123456",
      api_key: "key",
      json: -> {
        {
          include_aliases: {
            external_id: "1234567890"
          },
          contents: "Hello world",
          target_channel: "push"
        }
      }
    }
    set_config(@config)
  end

  test "sends push notification" do
    stub_request(:post, "https://api.onesignal.com/notifications?c=push").with(
      headers: {
        "Authorization" => "key",
        "Content-Type" => "application/json"
      },
      body: {
        include_aliases: {
          external_id: "1234567890"
        },
        contents: "Hello world",
        target_channel: "push",
        app_id: "123456"
      }
    ).to_return(status: 200)

    assert_nothing_raised do
      @delivery_method.deliver
    end
  end

  test "raises error on failure" do
    stub_request(:post, "https://api.onesignal.com/notifications?c=push").to_return(status: 400, body: '{"errors": ["This is an error"]}')
    assert_raises Noticed::ResponseUnsuccessful do
      @delivery_method.deliver
    end
  end

  test "passes error to notification instance if error_handler is configured" do
    @delivery_method = Noticed::DeliveryMethods::OneSignal.new(
      "delivery_method_name",
      noticed_notifications(:one)
    )

    error_handler_called = false
    @config[:error_handler] = lambda do |one_signal_error_message|
      error_handler_called = true
    end
    set_config(@config)

    stub_request(:post, "https://api.onesignal.com/notifications?c=push").to_return(status: 400, body: '{"errors": ["This is an error"]}')
    assert_nothing_raised do
      @delivery_method.deliver
    end

    assert(error_handler_called, "Handler is called if response contains errors")
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
