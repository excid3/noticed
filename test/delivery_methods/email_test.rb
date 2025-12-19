require "test_helper"

class EmailTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @delivery_method = Noticed::DeliveryMethods::Email.new
    @notification = noticed_notifications(:one)
  end

  test "sends email (with args)" do
    set_config(
      mailer: "UserMailer",
      method: "new_comment",
      params: -> { {foo: :bar} },
      args: -> { ["hey"] }
    )

    assert_emails(1) do
      @delivery_method.deliver
    end
  end

  test "sends email (with kwargs)" do
    set_config(
      mailer: "UserMailer",
      method: "greeting",
      params: -> { {foo: :bar} },
      kwargs: -> { {body: "Custom"} }
    )

    assert_emails(1) do
      @delivery_method.deliver
    end
  end

  test "sends email (with kwargs, replacing default argument)" do
    set_config(
      mailer: "UserMailer",
      method: "greeting",
      params: -> { {foo: :bar} },
      kwargs: -> { {body: "Custom", subject: "Testing"} }
    )

    assert_emails(1) do
      @delivery_method.deliver
    end
  end

  test "raises the underlying ArgumentError if kwargs are missing" do
    set_config(
      mailer: "UserMailer",
      method: "greeting",
      params: -> { {foo: :bar} },
      kwargs: -> { {baz: 123} }
    )

    error = assert_raises ArgumentError do
      @delivery_method.deliver
    end

    assert_equal "missing keyword: :body", error.message
  end

  test "raises the underlying ArgumentError if unknown kwargs are given" do
    set_config(
      mailer: "UserMailer",
      method: "greeting",
      params: -> { {foo: :bar} },
      kwargs: -> { {body: "Test", baz: 123} }
    )

    error = assert_raises ArgumentError do
      @delivery_method.deliver
    end

    assert_equal "unknown keyword: :baz", error.message
  end

  test "accepts both args and kwargs" do
    set_config(
      mailer: "UserMailer",
      method: "greeting",
      params: -> { {foo: :bar} },
      args: -> { ["hey"] },
      kwargs: -> { {body: "Test"} }
    )

    assert_emails(1) do
      @delivery_method.deliver
    end
  end

  test "enqueues email" do
    set_config(
      mailer: "UserMailer",
      method: "receipt",
      enqueue: true
    )

    assert_enqueued_emails(1) do
      @delivery_method.deliver
    end
  end

  test "includes notification in params" do
    set_config(mailer: "UserMailer", method: "new_comment")
    assert_equal @notification, @delivery_method.params.fetch(:notification)
  end

  test "includes record in params" do
    set_config(mailer: "UserMailer", method: "new_comment")
    assert_equal @notification.record, @delivery_method.params.fetch(:record)
  end

  test "includes recipient in params" do
    set_config(mailer: "UserMailer", method: "new_comment")
    assert_equal @notification.recipient, @delivery_method.params.fetch(:recipient)
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
    @delivery_method.instance_variable_set :@notification, @notification
  end
end
