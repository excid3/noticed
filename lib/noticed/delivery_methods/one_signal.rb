module Noticed
  module DeliveryMethods
    class OneSignal < DeliveryMethod
      required_options :include_aliases

      def deliver
        response = post_request(url, headers:, json:)
        parsed_response = JSON.parse(response.body)

        # OneSignal might returns 200 with errors
        # - "All included devices are not subscribed"
        # - Invalid aliases
        if parsed_response.key?("errors")
          raise ResponseUnsuccessful.new(response, url, headers:, json:)
        end
      rescue Noticed::ResponseUnsuccessful => exception
        if exception.response.code.start_with?("4") && config[:error_handler]
          notification.instance_exec(exception.response, &config[:error_handler])
        else
          raise
        end
      end

      def json
        evaluate_option(:json).merge({app_id:}) || {
          app_id:,
          include_aliases:,
          contents: params.fetch(:contents),
          target_channel: "push"
        }
      end

      def url
        evaluate_option(:url) || "https://api.onesignal.com/notifications?c=push"
      end

      def headers
        {
          Authorization: api_key,
          accept: "application/json"
        }
      end

      def app_id
        evaluate_option(:app_id) || credentials.fetch(:app_id)
      end

      def api_key
        evaluate_option(:api_key) || credentials.fetch(:api_key)
      end

      def include_aliases
        evaluate_option(:include_aliases)
      end

      def credentials
        evaluate_option(:credentials) || Rails.application.credentials.one_signal
      end
    end
  end
end
