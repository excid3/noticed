module Noticed
  module DeliveryMethods
    class TwilioMessaging < DeliveryMethod
      def deliver
        post_request url, basic_auth: {user: account_sid, pass: auth_token}, form: json.stringify_keys
      rescue Noticed::ResponseUnsuccessful => exception
        if exception.response.code.start_with?("4") && config[:error_handler]
          notification.instance_exec(exception.response, &config[:error_handler])
        else
          raise
        end
      end

      def json
        evaluate_option(:json) || {
          From: phone_number,
          To: recipient.phone_number,
          Body: params.fetch(:message)
        }
      end

      def url
        evaluate_option(:url) || "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json"
      end

      def account_sid
        evaluate_option(:account_sid) || credentials.fetch(:account_sid)
      end

      def auth_token
        evaluate_option(:auth_token) || credentials.fetch(:auth_token)
      end

      def phone_number
        evaluate_option(:phone_number) || credentials.fetch(:phone_number)
      end

      def credentials
        evaluate_option(:credentials) || Rails.application.credentials.twilio
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_delivery_methods_twilio_messaging, Noticed::DeliveryMethods::TwilioMessaging
