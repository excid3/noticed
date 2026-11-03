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
  test "keeps the webhook URL out of the error and the log" do
    url = "https://discord.example.org/api/webhooks/123/SECRET-TOKEN"
    stub_request(:post, url).to_return(status: 429)
    delivery_method = Noticed::DeliveryMethods::Discord.new
    delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(url: url, json: {})
    log = StringIO.new
    logger = Noticed::DeliveryMethod.logger
    Noticed::DeliveryMethod.logger = ActiveSupport::Logger.new(log)

    error = assert_raises(Noticed::ResponseUnsuccessful) { delivery_method.deliver }

    refute_includes error.message, "SECRET-TOKEN"
    assert_includes error.message, "https://discord.example.org"
    refute_includes log.string, "SECRET-TOKEN"
  ensure
    Noticed::DeliveryMethod.logger = logger
  end
end
