require "apnotic"

module Noticed
  module DeliveryMethods
    class Ios < DeliveryMethod
      required_options :bundle_identifier, :key_id, :team_id, :apns_key, :device_tokens

      # A connection is opened per delivery and closed afterwards. Long-lived connections
      # get reset by Apple when idle, which stalls the next push for over a minute.
      def deliver
        connection = new_connection

        evaluate_option(:device_tokens).each do |device_token|
          apn = Apnotic::Notification.new(device_token)
          format_notification(apn)

          response = connection.push(apn)
          raise "Timeout sending iOS push notification" unless response

          if bad_token?(response) && config[:invalid_token]
            # Allow notification to cleanup invalid iOS device tokens
            notification.instance_exec(device_token, &config[:invalid_token])
          elsif !response.ok?
            raise "Request failed #{response.body}"
          end
        end
      ensure
        connection&.close
      end

      private

      def format_notification(apn)
        apn.topic = evaluate_option(:bundle_identifier)

        method = config[:format]
        # Call method on Notifier if defined
        if method&.is_a?(Symbol) && event.respond_to?(method, true)
          event.send(method, notification, apn)
        # If Proc, evaluate it on the Notification
        elsif method&.respond_to?(:call)
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

      def new_connection
        connection = evaluate_option(:development) ? Apnotic::Connection.development(connection_options) : Apnotic::Connection.new(connection_options)
        connection.on(:error) do |exception|
          Rails.logger.info "Apnotic exception raised: #{exception}"
          notification.instance_exec(exception, &config[:error_handler]) if config[:error_handler]
        end
        connection
      end

      def connection_options
        {
          auth_method: :token,
          cert_path: StringIO.new(evaluate_option(:apns_key)),
          key_id: evaluate_option(:key_id),
          team_id: evaluate_option(:team_id)
        }
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_delivery_methods_ios, Noticed::DeliveryMethods::Ios
