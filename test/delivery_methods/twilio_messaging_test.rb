require "test_helper"

class TwilioMessagingTest < ActiveSupport::TestCase
  setup do
    @delivery_method = Noticed::DeliveryMethods::TwilioMessaging.new
    set_config(
      account_sid: "acct_1234",
      auth_token: "token",
      json: -> {
        {
          From: "+1234567890",
          To: "+1234567890",
          Body: "Hello world"
        }
      }
    )
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

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
