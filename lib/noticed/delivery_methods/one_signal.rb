module Noticed
  module DeliveryMethods
    class OneSignal < DeliveryMethod
      required_options :include_aliases, :target_channel

      def deliver
        response = post_request(url, headers: headers, json: json)
        parsed_response = JSON.parse(response.body)

        # OneSignal might returns 200 with errors
        # - "All included devices are not subscribed"
        # - Invalid aliases
        if parsed_response.key?("errors")
          raise ResponseUnsuccessful.new(response, url, headers: headers, json: json)
        end
      rescue Noticed::ResponseUnsuccessful => exception
        if exception.response.code.start_with?("4") && config[:error_handler]
          notification.instance_exec(exception.response, &config[:error_handler])
        else
          raise
        end
      end

      def json
        evaluate_option(:json).merge({app_id: app_id, target_channel: target_channel}) || {
          app_id: app_id,
          include_aliases: include_aliases,
          contents: params.fetch(:contents),
          target_channel: target_channel
        }
      end

      def url
        evaluate_option(:url) || "https://api.onesignal.com/notifications?c=#{target_channel}"
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

      def target_channel
        evaluate_option(:target_channel)
      end

      def credentials
        evaluate_option(:credentials) || Rails.application.credentials.one_signal
      end
    end
  end
end
