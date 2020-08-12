module Noticed
  module DeliveryMethods
    class Twilio < Base
      def deliver
        post(url, basic_auth: {user: account_sid, pass: auth_token}, form: format)
      end

      private

      def format
        if (method = options[:format])
          notification.send(method)
        else
          {
            From: phone_number,
            To: recipient.phone_number,
            Body: notification.params[:message]
          }
        end
      end

      def url
        if (method = options[:url])
          notification.send(method)
        else
          "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json"
        end
      end

      def account_sid
        credentials.fetch(:account_sid)
      end

      def auth_token
        credentials.fetch(:auth_token)
      end

      def phone_number
        credentials.fetch(:phone_number)
      end

      def credentials
        if (method = options[:credentials])
          notification.send(method)
        else
          Rails.application.credentials.twilio
        end
      end
    end
  end
end
