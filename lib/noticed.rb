require "active_job/arguments"
require "http"
require "noticed/engine"

module Noticed
  extend ActiveSupport::Autoload

  autoload :Base
  autoload :Coder
  autoload :Model
  autoload :Translation

  module DeliveryMethods
    extend ActiveSupport::Autoload

    autoload :Base
    autoload :ActionCable
    autoload :Database
    autoload :Email
    autoload :Slack
    autoload :Test
    autoload :Twilio
    autoload :Vonage
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
