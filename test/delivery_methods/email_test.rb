require "test_helper"

class EmailTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "sends email" do
    assert_enqueued_emails 1 do
      CommentNotification.new.deliver(user)
    end
  end

  test "validates `mailer` is specified for email delivery method" do
    class EmailDeliveryWithoutMailer < Noticed::Base
      deliver_by :email
    end

    assert_raises Noticed::ValidationError do
      EmailDeliveryWithoutMailer.new.deliver(user)
    end
  end
end
