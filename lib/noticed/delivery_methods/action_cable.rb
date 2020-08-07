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
        @channel ||= begin
           value = options[:channel]
           case value
           when String
             value.constantize
           when Symbol
             notification.send(value)
           when Class
             value
           else
             Noticed::NotificationChannel
           end
         end
      end
    end
  end
end
