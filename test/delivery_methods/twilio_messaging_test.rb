require "test_helper"

class TwilioMessagingTest < ActiveSupport::TestCase
  setup do
    @delivery_method = Noticed::DeliveryMethods::TwilioMessaging.new
    @config = {
      account_sid: "acct_1234",
      auth_token: "token",
      json: -> {
        {
          From: "+1234567890",
          To: "+1234567890",
          Body: "Hello world"
        }
      }
    }
    set_config(@config)
  end

  test "sends sms" do
    stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/acct_1234/Messages.json").with(
      headers: {
        "Authorization" => "Basic YWNjdF8xMjM0OnRva2Vu",
        "Content-Type" => "application/x-www-form-urlencoded"
      },
      body: {
        From: "+1234567890",
        To: "+1234567890",
        Body: "Hello world"
      }
    ).to_return(status: 200)
    @delivery_method.deliver
  end

  test "raises error on failure" do
    stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/acct_1234/Messages.json").to_return(status: 422)
    assert_raises Noticed::ResponseUnsuccessful do
      @delivery_method.deliver
    end
  end

  test "passes error to notification instance if error_handler is configured" do
    @delivery_method = Noticed::DeliveryMethods::TwilioMessaging.new(
      "delivery_method_name",
      noticed_notifications(:one)
    )

    error_handler_called = false
    @config[:error_handler] = lambda do |twilio_error_message|
      error_handler_called = true
    end
    set_config(@config)

    stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/acct_1234/Messages.json").to_return(status: 422)
    assert_nothing_raised do
      @delivery_method.deliver
    end

    assert(error_handler_called, "Handler is called if status is 4xx")
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
