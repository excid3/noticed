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
          json: format_notification(device_token))
      rescue Noticed::ResponseUnsuccessful => exception
        if bad_token?(exception.response) && config[:invalid_token]
          notification.instance_exec(device_token, &config[:invalid_token])
        elsif config[:error_handler]
          notification.instance_exec(exception.response, &config[:error_handler])
        else
          raise
        end
      end

      def format_notification(device_token)
        method = config[:json]
        if method.is_a?(Symbol) && event.respond_to?(method, true)
          event.send(method, device_token)
        else
          notification.instance_exec(device_token, &method)
        end
      end

      # FCM returns 404 UNREGISTERED for tokens that are no longer valid. 400 INVALID_ARGUMENT is also
      # returned for malformed payloads, so only treat it as a bad token when the error points at the token.
      # https://firebase.google.com/docs/reference/fcm/rest/v1/ErrorCode
      def bad_token?(response)
        case response.code
        when "404"
          true
        when "400"
          error = JSON.parse(response.body).fetch("error", {})
          violations = error.fetch("details", []).flat_map { |detail| detail.fetch("fieldViolations", []) }
          violations.any? { |violation| violation["field"] == "message.token" } || error["message"].to_s.match?(/registration token/i)
        else
          false
        end
      rescue JSON::ParserError
        false
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
        @access_token ||= authorizer.fetch_access_token!["access_token"]
      end

      def authorizer
        @authorizer ||= (evaluate_option(:authorizer) || Google::Auth::ServiceAccountCredentials).make_creds(
          json_key_io: StringIO.new(credentials.to_json),
          scope: "https://www.googleapis.com/auth/firebase.messaging"
        )
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_delivery_methods_fcm, Noticed::DeliveryMethods::Fcm
