require "test_helper"

class Noticed::EventTest < ActiveSupport::TestCase
  class ExampleNotifier < Noticed::Event
    deliver_by :test
    required_params :message
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

  class CallbackNotifier < Noticed::Event
    deliver_by :test
    required_params :message

    before_deliver :set_message

    def set_message
      params[:message] = "new message"
    end
  end

  test "calls callbacks" do
    event = CallbackNotifier.with(message: "test").deliver
    assert_equal event.params[:message], "new message"
  end

  test "deliver extracts record from params" do
    account = accounts(:one)
    event = ExampleNotifier.with(message: "test", record: account).deliver
    assert_equal account, event.record
  end
end
