require "test_helper"

class EmailTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @delivery_method = Noticed::DeliveryMethods::Email.new
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

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end
