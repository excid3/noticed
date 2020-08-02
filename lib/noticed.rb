require "noticed/engine"

module Noticed
  autoload :Base, "noticed/base"

  module DeliveryMethods
    extend ActiveSupport::Autoload

    autoload :Base, "noticed/delivery_methods/base"
    autoload :ActionCable, "noticed/delivery_methods/action_cable"
    autoload :Database, "noticed/delivery_methods/database"
    autoload :Email, "noticed/delivery_methods/email"
    autoload :Slack, "noticed/delivery_methods/slack"
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
end
