# frozen_string_literal: true

require "test_helper"
require "generators/noticed/model_generator"

class Noticed::ModelGeneratorTest < ::Rails::Generators::TestCase
  tests ::Noticed::Generators::ModelGenerator

  # Check for file generation directly in the dummy app itself
  dummy_app_folder = File.expand_path("../dummy", __dir__)
  notification_model = File.expand_path("app/models/notification.rb", dummy_app_folder)
  migrations_wildcard = File.expand_path("db/migrate/*.rb", dummy_app_folder)
  destination dummy_app_folder
  existing_migrations = Dir[migrations_wildcard]
  new_migrations = []

  setup do
    # Temporarily rename out any existing app/models/notification.rb file
    File.rename(notification_model, "#{notification_model}xx") if File.exist?(notification_model)
  end

  teardown do
    # If the temporarily-renamed app/models/notification.rb file exists, put it back into place
    if File.exist?("#{notification_model}xx")
      File.delete(notification_model)
      File.rename("#{notification_model}xx", notification_model)
    end
    # Remove all newly-created migration files
    new_migrations.each { |migration_file| File.delete(migration_file) }
  end

  test "Active Record model and migration are built" do
    # The generator should create a model file and a migration
    run_generator

    # Check to see that the model file was built
    assert_file notification_model
    # Identify all newly-created migrations
    new_migrations = Dir[migrations_wildcard] - existing_migrations
    # Make sure among all new migrations that were created that only one is named such that it creates the notifications table
    assert_equal 1, new_migrations.count { |migration| migration.end_with?("_create_notifications.rb") }
  end
end
