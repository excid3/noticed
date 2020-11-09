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
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
  ActiveSupport::TestCase.fixtures :all
end

require "minitest/unit"
require "mocha/minitest"
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

  setup do
    WebMock.disable_net_connect!(allow: lambda do |uri|
      [
        "outlook.office.com",
      ].include? uri.host
    end)

    # stub_request(:post, /outlook.office.com/).to_return(File.new(file_fixture("microsoft_teams.txt")))
    stub_request(:post, /hooks.slack.com/).to_return(File.new(file_fixture("slack.txt")))
    stub_request(:post, /api.twilio.com/).to_return(File.new(file_fixture("twilio.txt")))
    stub_request(:post, /rest.nexmo.com/).to_return(File.new(file_fixture("vonage.txt")))
  end

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

  def without_webmock
    WebMock.disable!
    yield if block_given?
  ensure
    WebMock.enable!
  end
end
