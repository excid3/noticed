require "test_helper"

class IosTest < ActiveSupport::TestCase
  class FakeConnection
    class_attribute :invalid_tokens, default: []
    attr_reader :deliveries, :closed, :error_handler

    def initialize(response = nil)
      @response = response
      @deliveries = []
      @closed = false
    end

    def on(event, &block)
      @error_handler = block if event == :error
    end

    def push(apn)
      @deliveries.push(apn)
      @response
    end

    def close
      @closed = true
    end
  end

  class FakeResponse
    attr_reader :status, :body

    def initialize(status, body = {})
      @status = status
      @body = body
    end

    def ok?
      status.start_with?("20")
    end
  end

  setup do
    FakeConnection.invalid_tokens = []

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
        FakeConnection.invalid_tokens << device_token
      }
    )
  end

  test "notifies each device token" do
    connection = FakeConnection.new(FakeResponse.new("200"))
    @delivery_method.stub(:new_connection, connection) do
      @delivery_method.deliver
    end

    assert_equal 2, connection.deliveries.count
    assert_equal 0, FakeConnection.invalid_tokens.count
  end

  test "notifies of invalid tokens for cleanup" do
    connection = FakeConnection.new(FakeResponse.new("410"))
    @delivery_method.stub(:new_connection, connection) do
      @delivery_method.deliver
    end

    # Our fake connection doesn't understand these wouldn't be delivered in the real world
    assert_equal 2, connection.deliveries.count
    assert_equal 2, FakeConnection.invalid_tokens.count
  end

  test "closes the connection after delivery" do
    connection = FakeConnection.new(FakeResponse.new("200"))
    @delivery_method.stub(:new_connection, connection) do
      @delivery_method.deliver
    end

    assert connection.closed
  end

  test "closes the connection when delivery fails" do
    connection = FakeConnection.new(FakeResponse.new("500"))
    @delivery_method.stub(:new_connection, connection) do
      assert_raises(RuntimeError) { @delivery_method.deliver }
    end

    assert connection.closed
  end

  test "error handler is bound to the notification being delivered" do
    handled = nil
    set_config(
      bundle_identifier: "bundle_id",
      key_id: "key_id",
      team_id: "team_id",
      apns_key: "apns_key",
      device_tokens: [],
      error_handler: ->(exception) { handled = [self, exception] }
    )

    connection = FakeConnection.new
    Apnotic::Connection.stub(:new, connection) do
      @delivery_method.send(:new_connection)
    end
    connection.error_handler.call("boom")

    assert_equal [noticed_notifications(:one), "boom"], handled
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
