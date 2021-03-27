require "active_job/arguments"
require "http"
require "noticed/engine"

module Noticed
  autoload :Base, "noticed/base"
  autoload :Coder, "noticed/coder"
  autoload :HasNotifications, "noticed/has_notifications"
  autoload :Model, "noticed/model"
  autoload :TextCoder, "noticed/text_coder"
  autoload :Translation, "noticed/translation"
  autoload :NotificationChannel, "noticed/notification_channel"

  module DeliveryMethods
    autoload :Base, "noticed/delivery_methods/base"
    autoload :ActionCable, "noticed/delivery_methods/action_cable"
    autoload :Database, "noticed/delivery_methods/database"
    autoload :Email, "noticed/delivery_methods/email"
    autoload :Slack, "noticed/delivery_methods/slack"
    autoload :MicrosoftTeams, "noticed/delivery_methods/microsoft_teams"
    autoload :Test, "noticed/delivery_methods/test"
    autoload :Twilio, "noticed/delivery_methods/twilio"
    autoload :Vonage, "noticed/delivery_methods/vonage"
  end

  def self.notify(recipients:, notification:)
    recipients.each do |recipient|
      notification.notify(recipient)
    end

    # Clear the recipient after sending to the group
    notification.recipient = nil
  end

  mattr_accessor :parent_class
  @@parent_class = "ApplicationJob"

  class ValidationError < StandardError
  end

  class ResponseUnsuccessful < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
    end
  end
end

# The following implements polyfills for Rails < 6.0
module ActionCable
  # If the Rails 6.0 ActionCable::TestHelper is missing then allow it to autoload
  unless ActionCable.const_defined? "TestHelper"
    autoload :TestHelper, "rails_6_polyfills/actioncable_test_helper.rb"
  end
  # If the Rails 6.0 test SubscriptionAdapter is missing then allow it to autoload
  unless ActionCable.const_defined? "SubscriptionAdapter::Test"
    module SubscriptionAdapter
      autoload :Test, "rails_6_polyfills/actioncable_test_adapter.rb"
    end
  end
end

# If the Rails 6.0 ActionJob DurationSerializer is missing then allow it to autoload
unless Object.const_defined?("ActiveJob::Serializers::DurationSerializer")
  require File.expand_path("rails_6_polyfills/activejob_duration_serializer.rb", __dir__)
end
