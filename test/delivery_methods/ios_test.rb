require "test_helper"

class IosTest < ActiveSupport::TestCase
  class FakeConnectionPool
    class_attribute :invalid_tokens, default: []
    attr_reader :deliveries

    def initialize(response)
      @response = response
      @deliveries = []
    end

    def with
      yield self
    end

    def push(apn)
      @deliveries.push(apn)
      @response
    end

    def close
    end
  end

  class FakeResponse
    attr_reader :status

    def initialize(status, body = {})
      @status = status
    end

    def ok?
      status.start_with?("20")
    end
  end

  setup do
    FakeConnectionPool.invalid_tokens = []

    @delivery_method = Noticed::DeliveryMethods::Ios.new
    @delivery_method.instance_variable_set :@notification, noticed_notifications(:one)
    set_config(
      bundle_identifier: "bundle_id",
      key_id: "key_id",
      team_id: "team_id",
      apns_key: "apns_key",
      device_tokens: [:a, :b],
      format: ->(apn) {
        apn.alert = "Hello world"
        apn.custom_payload = {url: root_url(host: "example.org")}
      },
      invalid_token: ->(device_token) {
        FakeConnectionPool.invalid_tokens << device_token
      }
    )
  end

  test "notifies each device token" do
    connection_pool = FakeConnectionPool.new(FakeResponse.new("200"))
    @delivery_method.stub(:production_pool, connection_pool) do
      @delivery_method.deliver
    end

    assert_equal 2, connection_pool.deliveries.count
    assert_equal 0, FakeConnectionPool.invalid_tokens.count
  end

  test "notifies of invalid tokens for cleanup" do
    connection_pool = FakeConnectionPool.new(FakeResponse.new("410"))
    @delivery_method.stub(:production_pool, connection_pool) do
      @delivery_method.deliver
    end

    # Our fake connection pool doesn't understand these wouldn't be delivered in the real world
    assert_equal 2, connection_pool.deliveries.count
    assert_equal 2, FakeConnectionPool.invalid_tokens.count
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
