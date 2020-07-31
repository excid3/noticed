module Noticed
  module DeliveryMethods
    class ActionCable < Base
      def deliver
        websocket_channel.broadcast_to recipient, format_for_websocket
      end

      def format_for_websocket
        notification.params
      end

      def websocket_channel
        Noticed::NotificationChannel
      end
    end
  end
end
