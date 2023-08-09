require "apnotic"

module Noticed
  module DeliveryMethods
    class Ios < Base
      cattr_accessor :connection_pool
      cattr_accessor :development_connection_pool

      def deliver
        raise ArgumentError, "bundle_identifier is missing" if bundle_identifier.blank?
        raise ArgumentError, "key_id is missing" if key_id.blank?
        raise ArgumentError, "team_id is missing" if team_id.blank?
        raise ArgumentError, "Could not find APN cert at '#{cert_path}'" unless valid_cert_path?

        device_tokens.each do |device_token|
          connection_pool.with do |connection|
            apn = Apnotic::Notification.new(device_token)
            format_notification(apn)

            response = connection.push(apn)
            raise "Timeout sending iOS push notification" unless response

            if bad_token?(response)
              # Allow notification to cleanup invalid iOS device tokens
              cleanup_invalid_token(device_token)
            elsif !response.ok?
              raise "Request failed #{response.body}"
            end
          end
        end

        development_device_tokens.each do |device_token|
          development_connection_pool.with do |connection|
            apn = Apnotic::Notification.new(device_token)
            format_notification(apn)

            response = connection.push(apn)
            raise "Timeout sending iOS push notification" unless response

            if bad_token?(response)
              # Allow notification to cleanup invalid iOS device tokens
              cleanup_invalid_token(device_token)
            elsif !response.ok?
              raise "Request failed #{response.body}"
            end
          end
        end
      end

      private

      def format_notification(apn)
        apn.topic = bundle_identifier

        if (method = options[:format])
          notification.send(method, apn)
        elsif params[:message].present?
          apn.alert = params[:message]
        else
          raise ArgumentError, "No message for iOS delivery. Either include message in params or add the 'format' option in 'deliver_by :ios'."
        end
      end

      def device_tokens
        if notification.respond_to?(:ios_device_tokens)
          Array.wrap(notification.ios_device_tokens(recipient))
        else
          raise NoMethodError, <<~MESSAGE
            You must implement `ios_device_tokens` to send iOS notifications

            # This must return an Array of iOS device tokens
            def ios_device_tokens(recipient)
              recipient.ios_device_tokens.pluck(:token)
            end
          MESSAGE
        end
      end

      def development_device_tokens
        if notification.respond_to?(:ios_development_device_tokens)
          Array.wrap(notification.ios_development_device_tokens(recipient))
        elsif development?
          raise NoMethodError, <<~MESSAGE
            You must implement `ios_development_device_tokens` to send iOS notifications
            to sandbox devices (XCode, Simulator, etc.). The current Rails enivronment
            is unrelated to to the environment the push token was generated in.

            # This must return an Array of iOS device tokens
            def ios_development_device_tokens(recipient)
              recipient.ios_device_tokens.pluck(:token)
            end
          MESSAGE
        else
          []
        end
      end

      def bad_token?(response)
        response.status == "410" || (response.status == "400" && response.body["reason"] == "BadDeviceToken")
      end

      def cleanup_invalid_token(token)
        return unless notification.respond_to?(:cleanup_device_token)
        notification.send(:cleanup_device_token, token: token, platform: "iOS")
      end

      def connection_pool
        self.class.connection_pool ||= new_connection_pool
      end

      def development_connection_pool
        self.class.development_connection_pool ||= new_development_connection_pool
      end

      def new_connection_pool
        handler = proc do |connection|
          connection.on(:error) do |exception|
            Rails.logger.info "Apnotic exception raised: #{exception}"
          end
        end

        Apnotic::ConnectionPool.new(connection_pool_options, pool_options, &handler)
      end

      def new_development_connection_pool
        handler = proc do |connection|
          connection.on(:error) do |exception|
            Rails.logger.info "Apnotic exception raised: #{exception}"
          end
        end

        Apnotic::ConnectionPool.development(connection_pool_options, pool_options, &handler)
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
        option = options[:bundle_identifier]
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
        option = options[:cert_path]
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
        option = options[:key_id]
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
        option = options[:team_id]
        case option
        when String
          option
        when Symbol
          notification.send(option)
        else
          Rails.application.credentials.dig(:ios, :team_id)
        end
      end

      # Do you want to support sending APNs to sandbox devices
      # (XCode, Simulator, etc.)?  For example, a staging rails environment,
      # with a com.app.staging bundle identifier, would POST development device tokens
      # from an XCode build, and production tokens from TestFlight. When receiving
      # a token from the client, it's up to the client to indicate if it's a sandboxed token.
      def development?
        option = options[:development]
        case option
        when Symbol
          !!notification.send(option)
        else
          !!option
        end
      end

      def valid_cert_path?
        case cert_path
        when File, StringIO
          cert_path.size > 0
        else
          File.exist?(cert_path)
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
