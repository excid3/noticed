require "test_helper"

class EmailDeliveryWithoutMailer < Noticed::Base
  deliver_by :email
end

class EmailDeliveryWithActiveJob < Noticed::Base
  deliver_by :email, mailer: "UserMailer", enqueue: true, method: "comment_notification"
end

class EmailDeliveryWithArguments < Noticed::Base
  deliver_by :email, mailer: "UserMailer", method: :comment_notification_for, args: :email_args

  def email_args
    recipient
  end
end

class EmailDeliveryWithNamedArguments < Noticed::Base
  deliver_by :email, mailer: "UserMailer", method: :comment_notification_with, named_args: :email_named_args

  def email_named_args
    {user: recipient}
  end
end

class EmailTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "sends email" do
    assert_emails 1 do
      CommentNotification.new.deliver(user)
    end
  end

  test "validates `mailer` is specified for email delivery method" do
    assert_raises Noticed::ValidationError do
      EmailDeliveryWithoutMailer.new.deliver(user)
    end
  end

  test "deliver returns the email object" do
    args = {
      notification_class: "Noticed::Base",
      recipient: user,
      options: {
        mailer: "UserMailer",
        method: "comment_notification"
      }
    }
    email = Noticed::DeliveryMethods::Email.new.perform(args)

    assert_kind_of Mail::Message, email
  end

  test "delivery spawns an ActiveJob for email" do
    EmailDeliveryWithActiveJob.new.deliver(user)
    assert_enqueued_emails 1
  end

  test "delivers an email when passing an argument" do
    assert_emails 1 do
      EmailDeliveryWithArguments.new.deliver(user)
    end
  end

  test "delivers an email when passing a named argument" do
    assert_emails 1 do
      EmailDeliveryWithNamedArguments.new.deliver(user)
    end
  end
end
