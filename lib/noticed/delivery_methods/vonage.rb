module Noticed
  module DeliveryMethods
    module Vonage
      extend ActiveSupport::Concern

      included do
        deliver_with :vonage
      end

      def deliver_with_vonage
        HTTP.post(
          "https://rest.nexmo.com/sms/json",
          json: format_for_vonage
        )
      end

      def format_for_vonage
        {
          api_key: vonage_credentials[:api_key],
          api_secret: vonage_credentials[:api_secret],
          from: notification.params[:from],
          text: notification.params[:body],
          to: notification.params[:to],
          type: "unicode"
        }
      end

      def vonage_credentials
        Rails.application.credentials.vonage
      end
    end
  end
end
