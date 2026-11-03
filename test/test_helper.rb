# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"
require "minitest/mock"
require "webmock/minitest"

# Load fixtures from the engine
ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
ActiveSupport::TestCase.fixtures :all

class ActiveSupport::TestCase
  # Captures what delivery methods log so tests can assert on it
  def with_captured_log
    log = StringIO.new
    original_logger = Noticed::DeliveryMethod.logger
    Noticed::DeliveryMethod.logger = ActiveSupport::Logger.new(log)
    yield log
  ensure
    Noticed::DeliveryMethod.logger = original_logger
  end
end
