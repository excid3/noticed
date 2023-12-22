require "test_helper"

class NotifierTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class SimpleNotifier < Noticed::Event
    deliver_by :test
    required_params :message

    def url
      root_url(host: "example.org")
    end
  end

  class InheritedNotifier < SimpleNotifier
  end

  class BulkNotifier < Noticed::Event
    bulk_deliver_by :webhook, url: "https://example.org/bulk"
  end

  test "includes Rails urls" do
    assert_equal "http://example.org/", SimpleNotifier.new.url
  end

  test "notifiers inherit required params" do
    assert_equal [:message], InheritedNotifier.required_params
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
end
