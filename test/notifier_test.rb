require "test_helper"

class NotifierTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "includes Rails urls" do
    assert_equal "http://example.org/", SimpleNotifier.new.url
  end

  test "notifiers inherit required params" do
    assert_equal [:message], InheritedNotifier.required_params
  end

  test "serializes globalid objects with text column" do
    user = users(:one)
    notification = Noticed::Event.create!(type: "SimpleNotifier", params: {user: user})
    assert_equal({user: user}, notification.params)
  end

  test "deliver creates an event" do
    assert_difference "Noticed::Event.count" do
      ReceiptNotifier.deliver(User.first)
    end
  end

  test "deliver creates notifications for each recipient" do
    assert_no_difference "Noticed::Notification.count" do
      ReceiptNotifier.deliver
    end

    assert_difference "Noticed::Notification.count" do
      ReceiptNotifier.deliver(User.first)
    end

    assert_difference "Noticed::Notification.count", User.count do
      ReceiptNotifier.deliver(User.all)
    end
  end

  test "creates jobs for deliveries" do
    # Delivering a notification creates records
    assert_enqueued_jobs 1, only: Noticed::EventJob do
      ReceiptNotifier.deliver(User.first)
    end

    # Run the Event Job
    assert_enqueued_jobs 1, only: Noticed::DeliveryMethods::Test do
      perform_enqueued_jobs
    end

    # Run the individual deliveries
    perform_enqueued_jobs

    assert_equal Noticed::Notification.last, Noticed::DeliveryMethods::Test.delivered.last
  end

  test "creates jobs for bulk deliveries" do
    assert_enqueued_jobs 1, only: Noticed::EventJob do
      BulkNotifier.deliver
    end

    assert_enqueued_jobs 1, only: Noticed::BulkDeliveryMethods::Webhook do
      perform_enqueued_jobs
    end
  end

  test "deliver wait" do
    freeze_time
    assert_enqueued_with job: Noticed::EventJob, at: 5.minutes.from_now do
      ReceiptNotifier.deliver(User.first, wait: 5.minutes)
    end
  end

  test "deliver queue" do
    freeze_time
    assert_enqueued_with job: Noticed::EventJob, queue: :low_priority do
      ReceiptNotifier.deliver(User.first, queue: :low_priority)
    end
  end

  test "wait delivery method option" do
    freeze_time
    event = WaitNotifier.deliver(User.first)
    assert_enqueued_with(job: Noticed::DeliveryMethods::Test, args: [:test, event.notifications.last], at: 5.minutes.from_now) do
      perform_enqueued_jobs
    end
  end

  test "wait_until delivery method option" do
    freeze_time
    event = WaitUntilNotifier.deliver(User.first)
    assert_enqueued_with(job: Noticed::DeliveryMethods::Test, args: [:test, event.notifications.last], at: 1.hour.from_now) do
      perform_enqueued_jobs
    end
  end

  test "queue delivery method option" do
    event = QueueNotifier.deliver(User.first)
    assert_enqueued_with(job: Noticed::DeliveryMethods::Test, args: [:test, event.notifications.last], queue: "example_queue") do
      perform_enqueued_jobs
    end
  end

  # assert_enqeued_with doesn't support priority before Rails 7
  if Rails.gem_version >= Gem::Version.new("7.0.0.alpha1")
    test "priority delivery method option" do
      event = PriorityNotifier.deliver(User.first)
      assert_enqueued_with(job: Noticed::DeliveryMethods::Test, args: [:test, event.notifications.last], priority: 2) do
        perform_enqueued_jobs
      end
    end
  end
end
