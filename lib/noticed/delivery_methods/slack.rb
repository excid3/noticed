module Noticed
  module DeliveryMethods
    class Slack < DeliveryMethod
      DEFAULT_URL = "https://slack.com/api/chat.postMessage"

      required_options :json

      def deliver
        post_request url, headers: evaluate_option(:headers), json: evaluate_option(:json)
      end

      def url
        evaluate_option(:url) || DEFAULT_URL
      end
    end
  end
end
