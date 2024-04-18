require "test_helper"

class EmailTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @delivery_method = Noticed::DeliveryMethods::Email.new
    @notification = noticed_notifications(:one)
  end

  test "sends email" do
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
