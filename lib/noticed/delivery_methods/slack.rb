module Noticed
  module DeliveryMethods
    class Slack < DeliveryMethod
      DEFAULT_URL = "https://slack.com/api/chat.postMessage"

      required_options :json

      def deliver
        headers = evaluate_option(:headers)
        json = evaluate_option(:json)
        response = post_request url, headers: headers, json: json

        if raise_if_not_ok?
          raise ResponseUnsuccessful.new(response, url, {headers: headers, json: json}) unless JSON.parse(response.body)["ok"]
        end

        response
      end

      def url
        evaluate_option(:url) || DEFAULT_URL
      end

      def raise_if_not_ok?
        value = evaluate_option(:raise_if_not_ok)
        value.nil? ? true : value
      end
    end
  end
end
