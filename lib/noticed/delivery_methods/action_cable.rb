module Noticed
  module DeliveryMethods
    class ActionCable < Base
      def deliver
        websocket_channel.broadcast_to recipient, format_for_websocket
      end

      def format_for_websocket
        if (method = options[:format])
          notification.send(method)
        else
          notification.params
        end
      end

      def websocket_channel
        if (method = options[:channel])
          notification.send(method)
        else
          Noticed::NotificationChannel
        end
      end
    end
  end
end
