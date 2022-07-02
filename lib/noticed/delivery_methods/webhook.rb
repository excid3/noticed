module Noticed
  module DeliveryMethods
    class Webhook < Base
      option :url

      def deliver
        post(url, json: format)
      end

      private

      def format
        if (method = options[:format])
          notification.send(method)
        else
          notification.params
        end
      end

      def url
        if (method = options[:url])
          notification.send(method)
        end
      end
    end
  end
end
