require "test_helper"

class EventJobTest < ActiveJob::TestCase
  module ::Noticed
    class DeliveryMethods::Test1 < DeliveryMethod; end

    class DeliveryMethods::Test2 < DeliveryMethod; end

    class BulkDeliveryMethods::Test1 < BulkDeliveryMethod; end

    class BulkDeliveryMethods::Test2 < BulkDeliveryMethod; end
  end

  test "enqueues jobs for each notification and delivery method" do
    Noticed::EventJob.perform_now(noticed_notifications(:one).event)
    assert_enqueued_jobs 3
  end

  test "skips enqueueing jobs if before_enqueue raises an error" do
    notification = noticed_notifications(:one)
    event = notification.event
    event.class.deliver_by :test1 do |config|
      config.before_enqueue = -> { false }
    end
    event.class.deliver_by :test2 do |config|
      config.before_enqueue = -> { throw :abort }
    end

    Noticed::EventJob.perform_now(event)
    assert_enqueued_jobs 4

    event.class.delivery_methods.delete(:test1)
    event.class.delivery_methods.delete(:test2)
  end

  test "skips enqueueing bulk delivery job if before_enqueue raises an error" do
    notification = noticed_notifications(:one)
    event = notification.event
    event.class.bulk_deliver_by :test1 do |config|
      config.before_enqueue = -> { false }
    end
    event.class.bulk_deliver_by :test2 do |config|
      config.before_enqueue = -> { throw :abort }
    end

    Noticed::EventJob.perform_now(event)
    assert_enqueued_jobs 4

    event.class.bulk_delivery_methods.delete(:test1)
    event.class.bulk_delivery_methods.delete(:test2)
  end
end
