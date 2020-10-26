module Noticed
  module DeliveryMethods
    class Team < Base
      def deliver
        post(url, json: format)
      end

      private

      def format
        if (method = options[:format])
          notification.send(method)
        else
          {
            title: notification.params[:title],
            text: notification.params[:text],
            sections: notification.params[:sections],
            potentialAction: notification.params[:notificationAction]
          }
        end
      end

      def url
        if (method = options[:url])
          notification.send(method)
        else
          Rails.application.credentials.teams[:notification_url]
        end
      end
    end
  end
end
