# frozen_string_literal: true

require "test_helper"
require "generators/noticed/notifier_generator.rb"

class Noticed::NotifierGeneratorTest < ::Rails::Generators::TestCase
  tests ::Noticed::Generators::NotifierGenerator

  destination Rails.root

  teardown do
    remove_if_exists("app/notifications/test_notifier.rb")
  end

  test "notificiation object is built" do
    run_generator ["TestNotifier"]
    assert_file "app/notifications/test_notifier.rb"
  end

  def remove_if_exists(path)
    full_path = Rails.root.join(path)
    FileUtils.rm_rf(full_path)
  end
end
