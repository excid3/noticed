require "test_helper"

class CoderTest < ActiveSupport::TestCase
  test "uses TextCoder for text columns" do
    assert_equal Noticed::TextCoder, Notification.noticed_coder
  end

  test "uses Coder for json columns" do
    assert_equal Noticed::Coder, JsonNotification.noticed_coder
  end

  test "uses Coder for jsonb columns" do
    assert_equal Noticed::Coder, JsonbNotification.noticed_coder
  end

  test "serializes globalid objects with text column" do
    notification = Notification.create!(recipient: user, type: "Example", params: {user: user})
    assert_equal({user: user}, notification.params)
  end

  test "serializes globalid objects with json column" do
    notification = JsonNotification.create!(recipient: user, type: "Example", params: {user: user})
    assert_equal({user: user}, notification.params)
  end

  test "serializes globalid objects with jsonb column" do
    notification = JsonbNotification.create!(recipient: user, type: "Example", params: {user: user})
    assert_equal({user: user}, notification.params)
  end
end
