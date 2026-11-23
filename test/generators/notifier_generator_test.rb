require "test_helper"
require "generators/noticed/notifier_generator"

class NotifierGeneratorTest < Rails::Generators::TestCase
  tests Noticed::Generators::NotifierGenerator
  destination File.expand_path("../dummy/tmp/generators", __dir__)
  setup :prepare_destination

  test "generates ApplicationNotifier when it doesn't exist" do
    ActiveSupport::Inflector.stub(:safe_constantize, nil) do
      run_generator ["NewComment"]
    end

    assert_file "app/notifiers/application_notifier.rb", /class ApplicationNotifier < Noticed::Event/
    assert_file "app/notifiers/new_comment_notifier.rb", /class NewCommentNotifier < ApplicationNotifier/
  end

  test "skips ApplicationNotifier when the constant is already defined" do
    # The dummy app defines ApplicationNotifier, like an engine would
    run_generator ["NewComment"]

    assert_no_file "app/notifiers/application_notifier.rb"
    assert_file "app/notifiers/new_comment_notifier.rb", /class NewCommentNotifier < ApplicationNotifier/
  end

  test "--parent sets the superclass and skips ApplicationNotifier" do
    ActiveSupport::Inflector.stub(:safe_constantize, nil) do
      run_generator ["NewComment", "--parent", "BaseNotifier"]
    end

    assert_no_file "app/notifiers/application_notifier.rb"
    assert_no_file "app/notifiers/base_notifier.rb"
    assert_file "app/notifiers/new_comment_notifier.rb", /class NewCommentNotifier < BaseNotifier/
  end

  test "parent defaults to config.generators.notifier" do
    config = Rails::Configuration::Generators.new
    config.notifier parent: "BaseNotifier"

    with_generator_config(config) do
      capture(:stdout) { Noticed::Generators::NotifierGenerator.start ["NewComment"], destination_root: destination_root }
    end

    assert_no_file "app/notifiers/application_notifier.rb"
    assert_file "app/notifiers/new_comment_notifier.rb", /class NewCommentNotifier < BaseNotifier/
  end

  private

  # Generators read config defaults when the class loads, so reload it around the config
  def with_generator_config(config)
    original = Rails::Generators.options.deep_dup
    Rails::Generators.configure!(config)
    reload_generator
    yield
  ensure
    Rails::Generators.options.replace(original)
    reload_generator
  end

  def reload_generator
    Noticed::Generators.send(:remove_const, :NotifierGenerator)
    load File.expand_path("../../lib/generators/noticed/notifier_generator.rb", __dir__)
  end
end
