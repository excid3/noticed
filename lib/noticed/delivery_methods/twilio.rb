module Noticed
  module DeliveryMethods
    module Twilio
      extend ActiveSupport::Concern

      included do
        deliver_with :twilio
      end

      def deliver_with_twilio
        HTTP.basic_auth(
          user: twilio_credentials[:account_sid],
          pass: twilio_credentials[:auth_token]
        ).post(url, json: format_for_twilio)
      end

      def format_for_twilio
        {
          Body: notification.params[:message],
          From: twilio_credentials[:number],
          To: recipient.phone_number
        }
      end

      def twilio_url
        "https://api.twilio.com/2010-04-01/Accounts/#{twilio_credentials(recipient)[:account_sid]}/Messages.json"
      end

      def twilio_credentials
        Rails.application.credentials.twilio
      end
    end
  end
end
