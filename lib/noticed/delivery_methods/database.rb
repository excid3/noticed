module Noticed
  module DeliveryMethods
    class Database < Base
      # Must return the database record
      def deliver
        recipient.send(association_name).create!(attributes)
      end

      private

      def association_name
        options[:association] || :notifications
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
