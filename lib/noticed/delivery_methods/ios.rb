require "apnotic"

module Noticed
  module DeliveryMethods
    class Ios < Base
      cattr_accessor :connection_pool

      def deliver
        device_tokens.each do |device_token|
          connection_pool.with do |connection|
            apn = Apnotic::Notification.new(device_token)
            format_notification(apn)

            response = connection.push(apn)
            raise "Timeout sending iOS push notification" unless response

            # Allow notification to cleanup invalid iOS device tokens
            cleanup_invalid_token(device_token) if bad_token?(response)
          end
        end
      end

      private

      def format_notification(apn)
        if (method = options[:format])
          notification.send(method, apn)
        else
          apn.alert = params[:message]
        end
      end

      def device_tokens
        notification.ios_device_tokens(recipient)
      end

      def bad_token?(response)
        response.status == "410" || (response.status == "400" && response.body["reaseon"] == "BadDeviceToken")
      end

      def cleanup_invalid_token(token)
        return unless notification.respond_to?(:cleanup_invalid_token)
        notification.send(:cleanup_invalid_token, device_token)
      end

      def connection_pool
        self.class.connection_pool ||= Apnotic::ConnectionPool.new({
          auth_method: :token,
          cert_path: Rails.root.join("config/certs/ios/production.p8"),
          key_id: Rails.application.credentials.dig(:ios, :key_id),
          team_id: Rails.application.credentials.dig(:ios, :team_id)
        }, size: options.fetch(:pool_size, 5)) do |connection|
          connection.on(:error) do |exception|
            Rails.logger.info "Apnotic exception raised: #{exception}"
          end
        end
      end
    end
  end
end
