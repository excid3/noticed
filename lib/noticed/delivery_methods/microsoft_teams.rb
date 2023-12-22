module Noticed
  module DeliveryMethods
    class MicrosoftTeams < DeliveryMethod
      required_options :json

      def deliver
        post_request url, headers: evaluate_option(:headers), json: evaluate_option(:json)
      end

      def url
        evaluate_option(:url) || Rails.application.credentials.dig(:microsoft_teams, :notification_url)
      end
    end
  end
end
