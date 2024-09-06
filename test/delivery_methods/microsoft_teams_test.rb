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

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
