require "test_helper"

class EphemeralNotifierTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  class BulkWebhookEphemeral < Noticed::Ephemeral
    bulk_deliver_by :webhook do |config|
      config.url = "https://example.org/ephemeral"
      config.json = -> { params }
    end
  end

  class BeforeEnqueueEphemeral < Noticed::Ephemeral
    deliver_by :test do |config|
      config.before_enqueue = -> { throw :abort unless recipient.email == "one@example.org" }
    end

    bulk_deliver_by :test do |config|
      config.before_enqueue = -> { throw :abort if params[:skip_bulk] }
    end
  end

  class WaitEphemeral < Noticed::Ephemeral
    deliver_by :test do |config|
      config.wait = -> { (recipient.email == "one@example.org") ? 10.minutes : 5.minutes }
    end
  end

  class RequiredParamsEphemeral < Noticed::Ephemeral
    required_param :message
    deliver_by :test
  end

  class ParentEphemeral < Noticed::Ephemeral
    notification_methods do
      def parent_method
      end
    end
  end

  class ChildEphemeral < ParentEphemeral
    deliver_by :test
  end

  test "can enqueue delivery methods" do
    assert_enqueued_jobs 3 do
      EphemeralNotifier.new(params: {foo: :bar}).deliver(User.last)
    end

    assert_emails 1 do
      perform_enqueued_jobs
    end
  end

  test "ephemeral has record shortcut" do
    assert_equal :foo, EphemeralNotifier.with(record: :foo).record
  end

  test "ephemeral notifier includes Rails urls" do
    assert_equal "http://localhost:3000/", EphemeralNotifier.new.root_url
  end

  test "deliver_later is an alias for deliver" do
    assert_enqueued_jobs 3 do
      EphemeralNotifier.with(foo: :bar).deliver_later(User.last)
    end
  end

  test "bulk delivery methods use the notifier config" do
    stub = stub_request(:post, "https://example.org/ephemeral").with(body: {message: "hello"}.to_json)

    perform_enqueued_jobs do
      BulkWebhookEphemeral.with(message: "hello").deliver
    end

    assert_requested stub
  end

  test "before_enqueue is honored for individual deliveries" do
    assert_enqueued_jobs 1, only: Noticed::DeliveryMethods::Test do
      BeforeEnqueueEphemeral.with(skip_bulk: true).deliver([users(:one), users(:two)])
    end
  end

  test "before_enqueue is honored for bulk deliveries" do
    assert_enqueued_jobs 1, only: Noticed::BulkDeliveryMethods::Test do
      BeforeEnqueueEphemeral.with(skip_bulk: false).deliver
    end

    assert_no_enqueued_jobs only: Noticed::BulkDeliveryMethods::Test do
      BeforeEnqueueEphemeral.with(skip_bulk: true).deliver
    end
  end

  test "wait option is evaluated in the notification context" do
    freeze_time
    assert_enqueued_with(job: Noticed::DeliveryMethods::Test, at: 10.minutes.from_now) do
      WaitEphemeral.deliver(users(:one))
    end
    assert_enqueued_with(job: Noticed::DeliveryMethods::Test, at: 5.minutes.from_now) do
      WaitEphemeral.deliver(users(:two))
    end
  end

  test "deliver accepts job options" do
    freeze_time
    assert_enqueued_with(job: Noticed::DeliveryMethods::Test, at: 1.hour.from_now, queue: "low_priority") do
      EphemeralNotifier.deliver(users(:one), wait: 1.hour, queue: :low_priority)
    end
  end

  test "validates required params" do
    assert_raises Noticed::ValidationError do
      RequiredParamsEphemeral.deliver(users(:one))
    end

    assert_nothing_raised do
      RequiredParamsEphemeral.with(message: "test").deliver(users(:one))
    end
  end

  test "inherits notification_methods from parent notifier" do
    assert ChildEphemeral::Notification.new.respond_to?(:parent_method)
  end
end
