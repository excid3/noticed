# frozen_string_literal: true

require "test_helper"
require "generators/noticed/notification_generator"

class Noticed::NotificationGeneratorTest < ::Rails::Generators::TestCase
  tests ::Noticed::Generators::NotificationGenerator

  destination Rails.root

  teardown do
    remove_if_exists("app/notifications/test_notification.rb")
  end

  test "notificiation object is built" do
    run_generator ["TestNotification"]
    assert_file "app/notifications/test_notification.rb"
  end

  def remove_if_exists(path)
    full_path = Rails.root.join(path)
    FileUtils.rm_rf(full_path)
  end
end
