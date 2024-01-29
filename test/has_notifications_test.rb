require "test_helper"

class HasNotificationsTest < ActiveSupport::TestCase
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
      SimpleNotifier.with(user: user, message: "test").deliver(user)
    end
  end

  test "association with custom name returns notifications" do
    assert_difference "user.notifications_as_owner.count" do
      SimpleNotifier.with(owner: user, message: "test").deliver(user)
    end
  end

  test "deletes notifications with matching param" do
    SimpleNotifier.with(user: user, message: "test").deliver(users(:two))

    assert_difference "Noticed::Event.count", -1 do
      user.destroy
    end
  end

  test "doesn't delete notifications when disabled" do
    SimpleNotifier.with(owner: user, message: "test").deliver(users(:two))

    assert_no_difference "Noticed::Event.count" do
      user.destroy
    end
  end

  def user
    @user ||= users(:one)
  end
end
