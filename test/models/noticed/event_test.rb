require "test_helper"

class Noticed::EventTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class ExampleNotifier < Noticed::Event
    deliver_by :test
    required_params :message
  end

  setup do
    clear_enqueued_jobs
  end

  test "validates required params" do
    assert_raises Noticed::ValidationError do
      ExampleNotifier.deliver
    end
  end

  test "deliver saves event" do
    assert_difference "Noticed::Event.count" do
      ExampleNotifier.with(message: "test").deliver
    end
  end

  test "deliver saves notifications" do
    assert_no_difference "Noticed::Notification.count" do
      ExampleNotifier.with(message: "test").deliver
    end

    assert_difference "Noticed::Notification.count" do
      ExampleNotifier.with(message: "test").deliver(users(:one))
    end

    assert_difference "Noticed::Notification.count", User.count do
      ExampleNotifier.with(message: "test").deliver(User.all)
    end
  end

  test "deliver extracts record from params" do
    account = accounts(:one)
    event = ExampleNotifier.with(message: "test", record: account).deliver
    assert_equal account, event.record
  end

  test "deserialize_error?" do
    assert noticed_events(:missing_account).deserialize_error?
  end

  test "defers job enqueuing until after transaction commits" do
    # This test verifies that the job is NOT enqueued if the transaction rolls back
    # This proves that after_commit is being used properly

    assert_no_enqueued_jobs only: Noticed::EventJob do
      ActiveRecord::Base.transaction do
        ExampleNotifier.with(message: "test").deliver(users(:one))
        raise ActiveRecord::Rollback
      end
    end

    # When transaction succeeds, job should be enqueued
    assert_enqueued_with job: Noticed::EventJob do
      ExampleNotifier.with(message: "test").deliver(users(:one))
    end
  end

  test "notifications are visible when job runs" do
    # This test verifies the race condition is fixed by ensuring notifications
    # are committed before the job tries to access them
    event = ExampleNotifier.with(message: "test").deliver(users(:one))

    # Verify the event and notification were created
    assert event.persisted?, "Event should be persisted"
    assert_equal 1, event.notifications.count, "Should have 1 notification"

    # Verify the job was enqueued
    assert_enqueued_jobs 1, only: Noticed::EventJob

    # When the job runs, it should be able to access the notifications
    perform_enqueued_jobs

    # Verify notifications are accessible and have the correct data
    event.reload
    notifications = event.notifications.to_a
    assert_equal 1, notifications.size, "Should have exactly 1 notification after job runs"
    assert_equal users(:one).class.base_class.name, notifications.first.recipient_type
    assert_equal users(:one).id, notifications.first.recipient_id
  end

  test "enqueues jobs with after_commit regardless of Rails version" do
    # This test verifies that jobs are enqueued successfully whether Rails
    # uses automatic deferral (Rails 7.2+) or manual after_commit (older Rails)

    assert_enqueued_with job: Noticed::EventJob do
      ExampleNotifier.with(message: "test").deliver(users(:one))
    end
  end

  test "respects user transaction rollback" do
    # This test verifies the most common scenario: user wraps deliver in a transaction.
    # deliver creates its own nested transaction internally.
    # If the user's transaction rolls back, the job should NOT be enqueued.

    assert_no_enqueued_jobs only: Noticed::EventJob do
      ActiveRecord::Base.transaction do
        # deliver creates a nested transaction internally
        ExampleNotifier.with(message: "test").deliver(users(:one))

        # User's transaction rolls back
        raise ActiveRecord::Rollback
      end
    end
  end

  test "enqueues jobs when user transaction commits" do
    # This test verifies that jobs ARE enqueued when the user's transaction commits.
    # deliver creates a nested transaction internally, but the job still enqueues correctly.

    assert_enqueued_with job: Noticed::EventJob do
      ActiveRecord::Base.transaction do
        # deliver creates a nested transaction internally
        ExampleNotifier.with(message: "test").deliver(users(:one))
        # User's transaction commits successfully
      end
    end
  end
end
