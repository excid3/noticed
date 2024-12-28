module Noticed
  module BulkDeliveryMethods
    class Slack < BulkDeliveryMethod
      DEFAULT_URL = "https://slack.com/api/chat.postMessage"

      required_options :json

      def deliver
        headers = evaluate_option(:headers)
        json = evaluate_option(:json)

        response = post_request url, headers: headers, json: json

        if raise_on_failure? && response.body
          parsed_response = JSON.parse(response.body)
          raise ResponseUnsuccessful.new(response, url, {headers: headers, json: json}) unless parsed_response["ok"]
        end

        response
      end

      def url
        evaluate_option(:url) || DEFAULT_URL
      end

      def raise_on_failure?
        evaluate_option(:raise_on_failure) || false
      end
    end
  end
end
