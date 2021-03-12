module Noticed
  module DeliveryMethods
    class MicrosoftTeams < Base
      def deliver
        post(url, json: format)
      end

      private

      def format
        if (method = options[:format])
          notifier.send(method)
        else
          {
            title: notifier.params[:title],
            text: notifier.params[:text],
            sections: notifier.params[:sections],
            potentialAction: notifier.params[:notification_action]
          }
        end
      end

      def url
        if (method = options[:url])
          notifier.send(method)
        else
          Rails.application.credentials.microsoft_teams[:notification_url]
        end
      end
    end
  end
end
