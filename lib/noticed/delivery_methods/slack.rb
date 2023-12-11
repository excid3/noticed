module Noticed
  module DeliveryMethods
    class Slack < Base
      def deliver
        post(url, json: format, headers: headers)
      end

      private

      def format
        if (method = options[:format])
          notification.send(method)
        else
          notification.params
        end
      end

      def headers
        if (method = options[:headers])
          notification.send(method)
        end
      end

      def url
        if (method = options[:url])
          notification.send(method)
        else
          Rails.application.credentials.slack[:notification_url]
        end
      end
    end
  end
end
