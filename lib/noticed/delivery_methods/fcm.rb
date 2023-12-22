require "googleauth"

module Noticed
  module DeliveryMethods
    class Fcm < DeliveryMethod
      required_option :credentials, :device_tokens, :json

      def deliver
        evaluate_option(:device_tokens).each do |device_token|
          send_notification device_token
        end
      end

      def send_notification(device_token)
        post_request("https://fcm.googleapis.com/v1/projects/#{credentials[:project_id]}/messages:send",
          headers: {authorization: "Bearer #{access_token}"},
          json: notification.instance_exec(device_token, &config[:json]))
      rescue Noticed::ResponseUnsuccessful => exception
        if exception.response.code == "404" && config[:invalid_token]
          notification.instance_exec(device_token, &config[:invalid_token])
        else
          raise
        end
      end

      def credentials
        @credentials ||= begin
          value = evaluate_option(:credentials)
          case value
          when Hash
            value
          when Pathname
            load_json(value)
          when String
            load_json(Rails.root.join(value))
          else
            raise ArgumentError, "FCM credentials must be a Hash, String, Pathname, or Symbol"
          end
        end
      end

      def load_json(path)
        JSON.parse(File.read(path), symbolize_names: true)
      end

      def access_token
        @authorizer ||= (evaluate_option(:authorizer) || Google::Auth::ServiceAccountCredentials).make_creds(
          json_key_io: StringIO.new(credentials.to_json),
          scope: "https://www.googleapis.com/auth/firebase.messaging"
        )
        @authorizer.fetch_access_token!["access_token"]
      end
    end
  end
end
