require "apnotic"

module Noticed
  module DeliveryMethods
    class Ios < DeliveryMethod
      cattr_accessor :development_connection_pool, :production_connection_pool

      required_options :bundle_identifier, :key_id, :team_id, :apns_key, :device_tokens

      def deliver
        evaluate_option(:device_tokens).each do |device_token|
          apn = Apnotic::Notification.new(device_token)
          format_notification(apn)

          connection_pool = (!!evaluate_option(:development)) ? development_pool : production_pool
          connection_pool.with do |connection|
            response = connection.push(apn)
            raise "Timeout sending iOS push notification" unless response

            if bad_token?(response) && config[:invalid_token]
              # Allow notification to cleanup invalid iOS device tokens
              notification.instance_exec(device_token, &config[:invalid_token])
            elsif !response.ok?
              raise "Request failed #{response.body}"
            end
          end
        end
      end

      private

      def format_notification(apn)
        apn.topic = evaluate_option(:bundle_identifier)

        if (method = config[:format])
          notification.instance_exec(apn, &method)
        elsif notification.params.try(:has_key?, :message)
          apn.alert = notification.params[:message]
        else
          raise ArgumentError, "No message for iOS delivery. Either include message in params or add the 'format' option in 'deliver_by :ios'."
        end
      end

      def bad_token?(response)
        response.status == "410" || (response.status == "400" && response.body["reason"] == "BadDeviceToken")
      end

      def development_pool
        self.class.development_connection_pool ||= new_connection_pool(development: true)
      end

      def production_pool
        self.class.production_connection_pool ||= new_connection_pool(development: false)
      end

      def new_connection_pool(development:)
        handler = proc do |connection|
          connection.on(:error) do |exception|
            Rails.logger.info "Apnotic exception raised: #{exception}"
          end
        end

        if development
          Apnotic::ConnectionPool.development(connection_pool_options, pool_options, &handler)
        else
          Apnotic::ConnectionPool.new(connection_pool_options, pool_options, &handler)
        end
      end

      def connection_pool_options
        {
          auth_method: :token,
          cert_path: StringIO.new(config.fetch(:apns_key)),
          key_id: config.fetch(:key_id),
          team_id: config.fetch(:team_id)
        }
      end

      def pool_options
        {size: evaluate_option(:pool_size) || 5}
      end
    end
  end
end
