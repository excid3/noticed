require "noticed/engine"

module Noticed
  autoload :Base, "noticed/base"

  module DeliveryMethods
    extend ActiveSupport::Autoload

    autoload :Base, "noticed/delivery_methods/base"
    autoload :Database, "noticed/delivery_methods/database"
    autoload :Email, "noticed/delivery_methods/email"
    autoload :Slack, "noticed/delivery_methods/slack"
    autoload :Test, "noticed/delivery_methods/test"
    autoload :Twilio, "noticed/delivery_methods/twilio"
    autoload :Vonage, "noticed/delivery_methods/vonage"
    autoload :Websocket, "noticed/delivery_methods/websocket"
  end

  def self.notify(recipients:, notification:)
    recipients.each do |recipient|
      notification.notify(recipient)
    end

    # Clear the recipient after sending to the group
    notification.recipient = nil
  end
end
