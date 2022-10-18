module Noticed
  module DeliveryMethods
    class Slack < Webhook

      private

      def url
        if (method = options[:url])
          super
        else
          Rails.application.credentials.slack[:notification_url]
        end
      end
    end
  end
end
