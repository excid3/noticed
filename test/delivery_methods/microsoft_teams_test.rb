require "test_helper"

class MicrosoftTeamsTest < ActiveSupport::TestCase
  setup do
    @delivery_method = Noticed::DeliveryMethods::MicrosoftTeams.new
    set_config(
      json: {foo: :bar},
      url: "https://teams.microsoft.com"
    )
  end

  test "sends a message" do
    stub_request(:post, "https://teams.microsoft.com").with(body: "{\"foo\":\"bar\"}")
    assert_nothing_raised do
      @delivery_method.deliver
    end
  end

  test "raises error on failure" do
    stub_request(:post, "https://teams.microsoft.com").to_return(status: 422)
    assert_raises Noticed::ResponseUnsuccessful do
      @delivery_method.deliver
    end
  end

  test "keeps the webhook URL out of the error and the log" do
    url = "https://example.webhook.office.com/webhookb2/group@tenant/IncomingWebhook/SECRET-TOKEN/SECRET-GUID"
    set_config(json: {}, url: url)
    stub_request(:post, url).to_return(status: 422)

    error = with_captured_log do |log|
      error = assert_raises(Noticed::ResponseUnsuccessful) { @delivery_method.deliver }
      refute_includes log.string, "SECRET-TOKEN"
      error
    end

    refute_includes error.message, "SECRET-TOKEN"
    assert_includes error.message, "https://example.webhook.office.com/webhookb2/group@tenant/IncomingWebhook/[FILTERED]"
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
