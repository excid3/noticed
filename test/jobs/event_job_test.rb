require "test_helper"

class EventJobTest < ActiveJob::TestCase
  module ::Noticed
    class DeliveryMethods::Test1 < DeliveryMethod; end

    class DeliveryMethods::Test2 < DeliveryMethod; end
  end

  test "enqueues jobs for each notification and delivery method" do
    Noticed::EventJob.perform_now(noticed_notifications(:one).event)
    assert_enqueued_jobs 3
  end

  test "skips enqueueing jobs if the conditional is false" do
    notification = noticed_notifications(:one)
    event = notification.event
    event.class.deliver_by :test1 do |config|
      config.if = -> { true }
    end
    event.class.deliver_by :test2 do |config|
      config.if = -> { false }
    end

    Noticed::EventJob.perform_now(event)
    assert_enqueued_jobs 4

    event.class.delivery_methods.delete(:test1)
    event.class.delivery_methods.delete(:test2)
  end
end
