# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"
require "byebug"

# Filter out the backtrace from minitest while preserving the one from other libraries.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

require "rails/test_unit/reporter"
Rails::TestUnitReporter.executable = "bin/test"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths << File.expand_path("../fixtures", __FILE__)
  ActionDispatch::IntegrationTest.fixture_paths << File.expand_path("../fixtures", __FILE__)
elsif ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
end

ActiveSupport::TestCase.file_fixture_path = File.expand_path("../fixtures/files", __FILE__)
ActiveSupport::TestCase.fixtures :all

require "minitest/unit"
require "webmock/minitest"

class ExampleNotification < Noticed::Base
  class_attribute :callback_responses, default: []

  deliver_by :test, foo: :bar
  deliver_by :database

  # after_deliver do
  #  self.class.callback_reponses << "delivered"
  # end
end

class ActiveSupport::TestCase
  include ActionCable::TestHelper
  include ActionMailer::TestHelper

  teardown do
    Noticed::DeliveryMethods::Test.clear!
  end

  private

  def user
    @user ||= users(:one)
  end

  def make_notification(params)
    ExampleNotification.with(params)
  end

  def stub_delivery_method_request(delivery_method:, matcher:, method: :post, type: :success)
    stub_request(method, matcher).to_return(File.new(file_fixture("#{delivery_method}/#{type}.txt")))
  end
end
