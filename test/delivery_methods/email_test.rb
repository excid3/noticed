require "test_helper"

class EmailTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "sends email" do
    assert_enqueued_emails 1 do
      CommentNotification.new.deliver(user)
    end
  end
end
