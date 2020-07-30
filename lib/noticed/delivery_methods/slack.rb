module Noticed
  module DeliveryMethods
    module Slack
      extend ActiveSupport::Concern

      included do
        deliver_with :slack
      end

      def deliver_with_slack
        HTTP.post(slack_url, json: format_for_slack)
      end

      def format_for_slack
        notification.params
      end

      def slack_url
        Rails.application.credentials.slack[:notification_url]
      end
    end
  end
end
