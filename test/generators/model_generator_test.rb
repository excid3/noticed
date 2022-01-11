# frozen_string_literal: true

require "test_helper"
require "generators/noticed/model_generator"

class Noticed::ModelGeneratorTest < ::Rails::Generators::TestCase
  tests ::Noticed::Generators::ModelGenerator

  destination Rails.root

  teardown do
    remove_if_exists("app/models/test_notification.rb")
    remove_if_exists("db/migrate")
    remove_if_exists("test")
  end

  test "Active Record model and migration are built" do
    run_generator ["TestNotification"]
    assert_file "app/models/test_notification.rb"
    assert_migration "db/migrate/create_test_notifications.rb"
  end

  def remove_if_exists(path)
    full_path = Rails.root.join(path)
    FileUtils.rm_rf(full_path)
  end
end
