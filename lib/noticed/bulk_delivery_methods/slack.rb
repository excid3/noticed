module Noticed
  module BulkDeliveryMethods
    class Slack < BulkDeliveryMethod
      DEFAULT_URL = "https://slack.com/api/chat.postMessage"

      required_options :json

      def deliver
        headers = evaluate_option(:headers)
        json = evaluate_option(:json)
        response = post_request url, headers: headers, json: json

        if raise_if_not_ok?
          is_successful_json = response.content_type == "application/json" && response.is_a?(Net::HTTPSuccess)
          is_successful_html = response.content_type == "text/html" && response.is_a?(Net::HTTPSuccess)

          unless is_successful_json || is_successful_html
            raise ResponseUnsuccessful.new(response, url, {headers: headers, json: json})
          end
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
