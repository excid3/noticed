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
            raise "Request failed #{response.body}" unless response.ok?

            # Allow notification to cleanup invalid iOS device tokens
            cleanup_invalid_token(device_token) if bad_token?(response)
          end
        end
      end

      private

      def format_notification(apn)
        apn.topic = bundle_identifier

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
        response.status == "410" || (response.status == "400" && response.body["reason"] == "BadDeviceToken")
      end

      def cleanup_invalid_token(token)
        return unless notification.respond_to?(:cleanup_invalid_token)
        notification.send(:cleanup_invalid_token, device_token)
      end

      def connection_pool
        self.class.connection_pool ||= new_connection_pool
      end

      def new_connection_pool
        handler = proc do |connection|
          connection.on(:error) do |exception|
            Rails.logger.info "Apnotic exception raised: #{exception}"
          end
        end

        if options[:development]
          Apnotic::ConnectionPool.development(connection_pool_options, pool_options, &handler)
        else
          Apnotic::ConnectionPool.new(connection_pool_options, pool_options, &handler)
        end
      end

      def connection_pool_options
        {
          auth_method: :token,
          cert_path: cert_path,
          key_id: key_id,
          team_id: team_id
        }
      end

      def bundle_identifier
        option = options.fetch(:bundle_identifier)
        case option
        when String
          option
        when Symbol
          notification.send(option)
        else
          Rails.application.credentials.dig(:ios, :bundle_identifier)
        end
      end

      def cert_path
        option = options.fetch(:cert_path)
        case option
        when String
          option
        when Symbol
          notification.send(option)
        else
          Rails.root.join("config/certs/ios/apns.p8")
        end
      end

      def key_id
        option = options.fetch(:key_id)
        case option
        when String
          option
        when Symbol
          notification.send(option)
        else
          Rails.application.credentials.dig(:ios, :key_id)
        end
      end

      def team_id
        option = options.fetch(:team_id)
        case option
        when String
          option
        when Symbol
          notification.send(option)
        else
          Rails.application.credentials.dig(:ios, :team_id)
        end
      end

      def pool_options
        {
          size: options.fetch(:pool_size, 5)
        }
      end
    end
  end
end
