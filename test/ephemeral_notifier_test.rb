require "test_helper"

class EphemeralNotifierTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

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
end
