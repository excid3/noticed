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
    autoload :ActionCable, "noticed/delivery_methods/action_cable"
    autoload :Base, "noticed/delivery_methods/base"
    autoload :Database, "noticed/delivery_methods/database"
    autoload :Email, "noticed/delivery_methods/email"
    autoload :Fcm, "noticed/delivery_methods/fcm"
    autoload :Ios, "noticed/delivery_methods/ios"
    autoload :MicrosoftTeams, "noticed/delivery_methods/microsoft_teams"
    autoload :Slack, "noticed/delivery_methods/slack"
    autoload :Test, "noticed/delivery_methods/test"
    autoload :Twilio, "noticed/delivery_methods/twilio"
    autoload :Vonage, "noticed/delivery_methods/vonage"
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
