module Noticed
  module DeliveryMethods
    class Slack < DeliveryMethod
      DEFAULT_URL = "https://slack.com/api/chat.postMessage"

      required_options :json

      def deliver
        headers = evaluate_option(:headers)
        json = evaluate_option(:json)
        response = post_request url, headers: headers, json: json

        if raise_if_not_ok? && !success?(response)
          raise ResponseUnsuccessful.new(response, url, {headers: headers, json: json})
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

      def success?(response)
        if response.content_type == "application/json"
          JSON.parse(response.body).dig("ok")
        else
          # https://api.slack.com/changelog/2016-05-17-changes-to-errors-for-incoming-webhooks
          response.is_a?(Net::HTTPSuccess)
        end
      end
    end
  end
end
