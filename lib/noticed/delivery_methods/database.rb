module Noticed
  module DeliveryMethods
    class Database < Base
      def deliver
        notification.record = recipient.notifications.create(attributes)
      end

      def attributes
        if (method = options[:format])
          notification.send(method)
        else
          {
            type: notification.class.name,
            params: notification.params
          }
        end
      end
    end
  end
end
