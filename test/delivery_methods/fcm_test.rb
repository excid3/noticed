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
          message: {
            token: device_token,
            notification: {title: "Title", body: "Body"}
          }
        }
      }
    )

    stub_request(:post, "https://fcm.googleapis.com/v1/projects/p_1234/messages:send").with(body: "{\"message\":{\"token\":\"a\",\"notification\":{\"title\":\"Title\",\"body\":\"Body\"}}}")
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/p_1234/messages:send").with(body: "{\"message\":{\"token\":\"b\",\"notification\":{\"title\":\"Title\",\"body\":\"Body\"}}}")

    assert_nothing_raised do
      @delivery_method.deliver
    end
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

  test "notifies of unregistered tokens for clean up" do
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

    body = {
      error: {
        code: 400,
        message: "The registration token is not a valid FCM registration token",
        status: "INVALID_ARGUMENT",
        details: [
          {"@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError", errorCode: "INVALID_ARGUMENT"},
          {"@type": "type.googleapis.com/google.rpc.BadRequest", fieldViolations: [{field: "message.token", description: "Invalid registration token"}]}
        ]
      }
    }
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/p_1234/messages:send").to_return(status: 400, body: body.to_json, headers: {})

    @delivery_method.deliver
    assert_equal 2, cleanups
  end

  test "invalid payloads are not treated as invalid tokens" do
    cleanups = 0
    errors = 0

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
      invalid_token: ->(device_token) { cleanups += 1 },
      error_handler: ->(response) { errors += 1 }
    )

    body = {
      error: {
        code: 400,
        message: "Invalid JSON payload received. Unknown name \"foo\" at 'message.notification': Cannot find field.",
        status: "INVALID_ARGUMENT",
        details: [{"@type": "type.googleapis.com/google.rpc.BadRequest", fieldViolations: [{field: "message.notification", description: "Invalid JSON payload received."}]}]
      }
    }
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/p_1234/messages:send").to_return(status: 400, body: body.to_json, headers: {})

    @delivery_method.deliver
    assert_equal 0, cleanups
    assert_equal 2, errors
  end

  test "fetches the access token once per delivery" do
    fetches = 0
    authorizer = Class.new(FakeAuthorizer) do
      define_method(:fetch_access_token!) do
        fetches += 1
        super()
      end
    end

    set_config(
      authorizer: authorizer,
      credentials: {"type" => "service_account", "project_id" => "p_1234"},
      device_tokens: [:a, :b],
      json: ->(device_token) { {message: {token: device_token}} }
    )
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/p_1234/messages:send")

    @delivery_method.deliver
    assert_equal 1, fetches
  end

  test "notifies error handler if exists for other errors" do
    error_notifications = 0

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
      error_handler: ->(response) { error_notifications += 1 }
    )

    stub_request(:post, "https://fcm.googleapis.com/v1/projects/p_1234/messages:send").to_return(status: 403, body: "", headers: {})

    @delivery_method.deliver
    assert_equal 2, error_notifications
  end

  test "re-raises errors if there is no error handler" do
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
      }
    )

    stub_request(:post, "https://fcm.googleapis.com/v1/projects/p_1234/messages:send").to_return(status: 403, body: "", headers: {})

    assert_raises(Noticed::ResponseUnsuccessful) do
      @delivery_method.deliver
    end
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
