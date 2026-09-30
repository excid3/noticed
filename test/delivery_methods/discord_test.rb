require "test_helper"

class DiscordDeliveryMethodTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class DiscordNotifier < Noticed::Event
    deliver_by :discord do |config|
      config.url = "https://discord.example.org/webhook"
      config.json = -> { {content: params[:message], recipient: recipient.email} }
    end
  end

  setup do
    @delivery_method = Noticed::DeliveryMethods::Discord.new
  end

  test "end to end" do
    stub = stub_request(:post, "https://discord.example.org/webhook").with(body: {content: "hello", recipient: users(:one).email}.to_json)

    perform_enqueued_jobs do
      DiscordNotifier.with(message: "hello").deliver(users(:one))
    end

    assert_requested stub
  end

  test "discord with json payload" do
    set_config(
      url: "https://discord.example.org/webhook",
      json: {content: "hello"}
    )
    stub_request(:post, "https://discord.example.org/webhook").with(body: "{\"content\":\"hello\"}")

    assert_nothing_raised do
      @delivery_method.deliver
    end
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
