module Noticed
  module DeliveryMethods
    class ActionCable < DeliveryMethod
      required_options :message

      def deliver
        channel.broadcast_to stream, evaluate_option(:message)
      end

      def channel
        fetch_constant(:channel) || Noticed::NotificationChannel
      end

      def stream
        evaluate_option(:stream) || recipient
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_delivery_methods_action_cable, Noticed::DeliveryMethods::ActionCable
