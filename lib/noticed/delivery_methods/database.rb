module Noticed
  module DeliveryMethods
    class Database < Base
      # Must return the database record
      def deliver
        recipient.notifications.create(attributes)
      end

      def attributes
        if (method = options[:format])
          notification.send(method)
        else
          {
            type: notification.class.name,
            params: params
          }
        end
      end
    end
  end
end
