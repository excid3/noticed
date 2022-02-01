require "googleauth"

# class CommentNotifier
#  deliver_by :fcm, credentials: Rails.root.join("config/certs/fcm.json"), format: :format_notification
#
#  deliver_by :fcm, credentials: :fcm_credentials
#   def fcm_credentials
#     { project_id: "api-12345" }
#   end
# end

module Noticed
  module DeliveryMethods
    class Fcm < Base
      BASE_URI = "https://fcm.googleapis.com/v1/projects/"

      option :format

      def deliver
        device_tokens.each do |device_token|
          post("#{BASE_URI}#{project_id}/messages:send", headers: {authorization: "Bearer #{access_token}"}, json: {message: format(device_token)})
        rescue ResponseUnsuccessful => exception
          if exception.response.code == 404
            cleanup_invalid_token(device_token)
          else
            raise
          end
        end
      end

      def cleanup_invalid_token(device_token)
        return unless notification.respond_to?(:cleanup_device_token)
        notification.send(:cleanup_device_token, token: device_token, platform: "fcm")
      end

      def credentials
        @credentials ||= begin
          option = options[:credentials]
          credentials_hash = case option
          when Hash
            option
          when Pathname
            load_json(option)
          when String
            load_json(Rails.root.join(option))
          when Symbol
            notification.send(option)
          else
            Rails.application.credentials.fcm
          end

          credentials_hash.symbolize_keys
        end
      end

      def load_json(path)
        JSON.parse(File.read(path))
      end

      def project_id
        credentials[:project_id]
      end

      def access_token
        token = authorizer.fetch_access_token!
        token["access_token"]
      end

      def authorizer
        @authorizer ||= options.fetch(:authorizer, Google::Auth::ServiceAccountCredentials).make_creds(
          json_key_io: StringIO.new(credentials.to_json),
          scope: "https://www.googleapis.com/auth/firebase.messaging"
        )
      end

      def format(device_token)
        notification.send(options[:format], device_token)
      end

      def device_tokens
        if notification.respond_to?(:fcm_device_tokens)
          Array.wrap(notification.fcm_device_tokens(recipient))
        else
          raise NoMethodError, <<~MESSAGE
            You must implement `fcm_device_tokens` to send Firebase Cloud Messaging notifications

            # This must return an Array of FCM device tokens
            def fcm_device_tokens(recipient)
              recipient.fcm_device_tokens.pluck(:token)
            end
          MESSAGE
        end
      end
    end
  end
end
