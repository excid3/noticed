require "test_helper"

class HasNotificationsTest < ActiveSupport::TestCase
  class DatabaseDelivery < Noticed::Base
    deliver_by :database
  end

  test "has_noticed_notifications" do
    assert User.respond_to?(:has_noticed_notifications)
  end

  test "noticed notifications association" do
    assert user.respond_to?(:notifications_as_user)
  end

  test "noticed notifications with custom name" do
    assert user.respond_to?(:notifications_as_owner)
  end

  test "association returns notifications" do
    assert_difference "user.notifications_as_user.count" do
      DatabaseDelivery.with(user: user).deliver(user)
    end
  end

  test "association with custom name returns notifications" do
    assert_difference "user.notifications_as_owner.count" do
      DatabaseDelivery.with(owner: user).deliver(user)
    end
  end

  test "deletes notifications with matching param" do
    DatabaseDelivery.with(user: user).deliver(users(:two))

    assert_difference "Notification.count", -1 do
      user.destroy
    end
  end

  test "doesn't delete notifications when disabled" do
    DatabaseDelivery.with(owner: user).deliver(users(:two))

    assert_no_difference "Notification.count" do
      user.destroy
    end
  end
end
