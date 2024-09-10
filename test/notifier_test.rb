require "test_helper"

class NotifierTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class RecipientsBlock < Noticed::Event
    recipients do
      params.fetch(:recipients)
    end
  end

  class RecipientsLambda < Noticed::Event
    recipients -> { params.fetch(:recipients) }
  end

  class RecipientsMethod < Noticed::Event
    recipients :recipients

    def recipients
      params.fetch(:recipients)
    end
  end

  test "includes Rails urls" do
    assert_equal "http://localhost:3000/", SimpleNotifier.new.url
  end

  test "notifiers inherit required params" do
    assert_equal [:message], InheritedNotifier.required_params
  end

  test "notification_methods adds methods to Noticed::Notifications" do
    user = users(:one)
    event = SimpleNotifier.with(message: "test").deliver(user)
    assert_equal "hello #{user.email}", event.notifications.last.message
  end

  test "notification_methods url helpers" do
    assert_equal "http://localhost:3000/", SimpleNotifier::Notification.new.url
  end

  test "serializes globalid objects with text column" do
    user = users(:one)
    notification = Noticed::Event.create!(type: "SimpleNotifier", params: {user: user})
    assert_equal({user: user}, notification.params)
  end

  test "assigns record association from params" do
    user = users(:one)
    notifier = RecordNotifier.with(record: user)
    assert_equal user, notifier.record
    assert_empty notifier.params
  end

  test "can add validations for record association" do
    notifier = RecordNotifier.with({})
    refute notifier.valid?
    assert_equal ["can't be blank"], notifier.errors[:record]
  end

  test "recipients block" do
    assert_equal [:foo, :bar], RecipientsBlock.with(recipients: [:foo, :bar]).evaluate_recipients
  end

  test "recipients lambda" do
    assert_equal [:foo, :bar], RecipientsLambda.with(recipients: [:foo, :bar]).evaluate_recipients
  end

  test "recipients" do
    assert_equal [:foo, :bar], RecipientsMethod.with(recipients: [:foo, :bar]).evaluate_recipients
  end

  test "deliver without recipients" do
    assert_nothing_raised do
      ReceiptNotifier.deliver
    end
  end

  test "deliver creates an event" do
    assert_difference "Noticed::Event.count" do
      ReceiptNotifier.deliver(User.first)
    end
  end

  test "deliver creates notifications for each recipient" do
    assert_no_difference "Noticed::Notification.count" do
      event = ReceiptNotifier.deliver
      assert_equal 0, event.notifications_count
    end

    assert_difference "Noticed::Notification.count" do
      event = ReceiptNotifier.deliver(User.first)
      assert_equal 1, event.notifications_count
    end

    assert_difference "Noticed::Notification.count", User.count do
      event = ReceiptNotifier.deliver(User.all)
      assert_equal User.count, event.notifications_count
    end

    assert_difference "Noticed::Notification.count", -1 do
      event = noticed_events(:one)
      event.notifications.destroy_all
      assert_equal 0, event.notifications_count
    end
  end

  test "deliver to STI recipient writes base class" do
    admin = Admin.first
    assert_difference "Noticed::Notification.count" do
      ReceiptNotifier.deliver(admin)
    end
    notification = Noticed::Notification.last
    assert_equal "User", notification.recipient_type
    assert_equal admin, notification.recipient
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

  test "creates jobs for bulk ephemeral deliveries" do
    assert_enqueued_jobs 1, only: Noticed::BulkDeliveryMethods::Test do
      EphemeralNotifier.deliver
    end

    assert_difference("Noticed::BulkDeliveryMethods::Test.delivered.length" => 1) do
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
    assert_enqueued_with job: Noticed::EventJob, queue: "low_priority" do
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

  test "deprecations don't cause problems" do
    assert_nothing_raised do
      Noticed.deprecator.silence do
        DeprecatedNotifier.with(message: "test").deliver_later
      end
    end
  end
end
