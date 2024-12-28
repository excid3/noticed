module Noticed
  module DeliveryMethods
    class Slack < DeliveryMethod
      DEFAULT_URL = "https://slack.com/api/chat.postMessage"

      required_options :json

      def deliver
        headers = evaluate_option(:headers)
        json = evaluate_option(:json)

        response = post_request url, headers: headers, json: json

        if fail_on_error? && response.body
          parsed_response = JSON.parse(response.body)
          raise ResponseUnsuccessful.new(response, url, {headers: headers, json: json}) unless parsed_response["ok"]
        end

        response
      end

      def url
        evaluate_option(:url) || DEFAULT_URL
      end

      def fail_on_error?
        evaluate_option(:fail_on_error) || false
      end
    end
  end
end
