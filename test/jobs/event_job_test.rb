require "test_helper"

class EventJobTest < ActiveJob::TestCase
  class CallbackNotifier < Noticed::Event
    deliver_by :test
    required_params :message

    before_test :set_message

    def set_message
      params[:message] = "new message"
    end
  end

  test "calls callbacks" do
    event = CallbackNotifier.with(message: "test")
    Noticed::Notification.create(recipient: User.first, event: event)
    Noticed::EventJob.perform_now(event)
    assert_equal event.params[:message], "new message"
  end
end
