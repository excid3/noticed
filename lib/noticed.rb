require "noticed/version"
require "noticed/engine"

module Noticed
  include ActiveSupport::Deprecation::DeprecatedConstantAccessor

  def self.deprecator # :nodoc:
    @deprecator ||= ActiveSupport::Deprecation.new
  end

  deprecate_constant :Base, "Noticed::Event", deprecator: deprecator

  autoload :ApiClient, "noticed/api_client"
  autoload :BulkDeliveryMethod, "noticed/bulk_delivery_method"
  autoload :Coder, "noticed/coder"
  autoload :DeliveryMethod, "noticed/delivery_method"
  autoload :RequiredOptions, "noticed/required_options"
  autoload :Translation, "noticed/translation"

  module BulkDeliveryMethods
    autoload :Discord, "noticed/bulk_delivery_methods/discord"
    autoload :Slack, "noticed/bulk_delivery_methods/slack"
    autoload :Webhook, "noticed/bulk_delivery_methods/webhook"
  end

  module DeliveryMethods
    include ActiveSupport::Deprecation::DeprecatedConstantAccessor
    deprecate_constant :Base, "Noticed::DeliveryMethod", deprecator: Noticed.deprecator

    autoload :ActionCable, "noticed/delivery_methods/action_cable"
    autoload :Email, "noticed/delivery_methods/email"
    autoload :Fcm, "noticed/delivery_methods/fcm"
    autoload :Ios, "noticed/delivery_methods/ios"
    autoload :MicrosoftTeams, "noticed/delivery_methods/microsoft_teams"
    autoload :Slack, "noticed/delivery_methods/slack"
    autoload :Test, "noticed/delivery_methods/test"
    autoload :TwilioMessaging, "noticed/delivery_methods/twilio_messaging"
    autoload :VonageSms, "noticed/delivery_methods/vonage_sms"
    autoload :Webhook, "noticed/delivery_methods/webhook"
  end

  mattr_accessor :parent_class
  @@parent_class = "Noticed::ApplicationJob"


  class ValidationError < StandardError
  end

  class ResponseUnsuccessful < StandardError
    attr_reader :response

    def initialize(response, url, args)
      @response = response
      @url = url
      @args = args

      super("POST request to #{url} returned #{response.code} response:\n#{response.body.inspect}")
    end
  end
end
