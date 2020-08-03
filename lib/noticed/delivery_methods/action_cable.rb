module Noticed
  module DeliveryMethods
    class ActionCable < Base
      def deliver
        channel.broadcast_to recipient, format
      end

      private

      def format
        if (method = options[:format])
          notification.send(method)
        else
          notification.params
        end
      end

      def channel
        if (method = options[:channel])
          notification.send(method)
        else
          Noticed::NotificationChannel
        end
      end
    end
  end
end
