module Noticed
  module DeliveryMethods
    class Slack < Base
      def deliver
        post(url, json: format)
      end

      private

      def format
        if (method = options[:format])
          notifier.send(method)
        else
          notifier.params
        end
      end

      def url
        if (method = options[:url])
          notifier.send(method)
        else
          Rails.application.credentials.slack[:notification_url]
        end
      end
    end
  end
end
