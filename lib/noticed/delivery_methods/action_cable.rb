module Noticed
  module DeliveryMethods
    class ActionCable < DeliveryMethod
      required_options :message

      def deliver
        channel = fetch_constant(:channel) || Noticed::NotificationChannel
        stream = evaluate_option(:stream) || recipient
        message = evaluate_option(:message)

        channel.broadcast_to stream, message
      end
    end
  end
end
