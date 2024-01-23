require "test_helper"

class FcmTest < ActiveSupport::TestCase
  class FakeAuthorizer
    def self.make_creds(options = {})
      new
    end

    def fetch_access_token!
      {"access_token" => "access-token-12341234"}
    end
  end

  setup do
    @delivery_method = Noticed::DeliveryMethods::Fcm.new
  end

  test "notifies each device token" do
    set_config(
      authorizer: FakeAuthorizer,
      credentials: {
        "type" => "service_account",
        "project_id" => "p_1234",
        "private_key_id" => "private_key"
      },
      device_tokens: [:a, :b],
      json: ->(device_token) {
        {
          token: device_token,
          notification: {title: "Title", body: "Body"}
        }
      }
    )

    stub_request(:post, "https://fcm.googleapis.com/v1/projects/p_1234/messages:send").with(body: "{\"message\":{\"token\":\"a\",\"notification\":{\"title\":\"Title\",\"body\":\"Body\"}}}")
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/p_1234/messages:send").with(body: "{\"message\":{\"token\":\"b\",\"notification\":{\"title\":\"Title\",\"body\":\"Body\"}}}")

    @delivery_method.deliver
  end

  test "notifies of invalid tokens for clean up" do
    cleanups = 0

    set_config(
      authorizer: FakeAuthorizer,
      credentials: {
        "type" => "service_account",
        "project_id" => "p_1234",
        "private_key_id" => "private_key"
      },
      device_tokens: [:a, :b],
      json: ->(device_token) {
        {
          message: {
            token: device_token,
            notification: {title: "Title", body: "Body"}
          }
        }
      },
      invalid_token: ->(device_token) { cleanups += 1 }
    )

    stub_request(:post, "https://fcm.googleapis.com/v1/projects/p_1234/messages:send").to_return(status: 404, body: "", headers: {})

    @delivery_method.deliver
    assert_equal 2, cleanups
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
