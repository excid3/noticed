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
end
