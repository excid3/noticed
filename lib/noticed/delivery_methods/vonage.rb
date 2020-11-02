module Noticed
  module DeliveryMethods
    class Vonage < Base
      def deliver
        response = post("https://rest.nexmo.com/sms/json", json: format)
        status = response.parse.dig("messages", 0, "status")
        if !options[:ignore_failure] && status != "0"
          raise ResponseUnsuccessful.new(response)
        end

        response
      end

      private

      def format
        if (method = options[:format])
          notification.send(method)
        else
          {
            api_key: credentials[:api_key],
            api_secret: credentials[:api_secret],
            from: notification.params[:from],
            text: notification.params[:body],
            to: notification.params[:to],
            type: "unicode"
          }
        end
      end

      def credentials
        if (method = options[:credentials])
          notification.send(method)
        else
          Rails.application.credentials.vonage
        end
      end
    end
  end
end
