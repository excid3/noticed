require "test_helper"

class DiscordDeliveryMethodTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class DiscordNotifier < Noticed::Event
    deliver_by :discord do |config|
      config.url = "https://discord.example.org/webhook"
      config.json = -> { {content: params[:message], recipient: recipient.email} }
    end
  end

  test "end to end" do
    stub = stub_request(:post, "https://discord.example.org/webhook").with(body: {content: "hello", recipient: users(:one).email}.to_json)

    perform_enqueued_jobs do
      DiscordNotifier.with(message: "hello").deliver(users(:one))
    end

    assert_requested stub
  end

  # A Discord webhook URL is the credential: anyone who has it can post to the channel
  test "keeps the webhook token out of the error and the log" do
    url = "https://discord.com/api/webhooks/123/SECRET-TOKEN"
    stub_request(:post, url).to_return(status: 429)
    @delivery_method = Noticed::DeliveryMethods::Discord.new
    set_config(url: url, json: {})

    log = capture_log do
      error = assert_raises(Noticed::ResponseUnsuccessful) { @delivery_method.deliver }
      assert_includes error.message, "POST request to https://discord.com/api/webhooks/123/[FILTERED] returned 429"
    end
    assert_includes log, "POST https://discord.com/api/webhooks/123/[FILTERED]"
    refute_includes log, "SECRET-TOKEN"
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
