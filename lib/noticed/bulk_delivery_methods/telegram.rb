module Noticed
  module BulkDeliveryMethods
    class Telegram < BulkDeliveryMethod
      required_options :bot_token, :chat_id

      def deliver
        response = post_request url, json: json_payload

        if raise_if_not_ok? && !success?(response)
          raise ResponseUnsuccessful.new(response, url, {json: json_payload})
        end

        response
      end

      def url
        "https://api.telegram.org/bot#{evaluate_option(:bot_token)}/sendMessage"
      end

      def json_payload
        payload = {
          chat_id: evaluate_option(:chat_id)
        }

        # Add text if provided
        text = evaluate_option(:text) if config.has_key?(:text)
        payload[:text] = text if text

        # Add optional parameters if provided
        payload[:parse_mode] = evaluate_option(:parse_mode) if config.has_key?(:parse_mode)
        payload[:disable_web_page_preview] = evaluate_option(:disable_web_page_preview) if config.has_key?(:disable_web_page_preview)
        payload[:disable_notification] = evaluate_option(:disable_notification) if config.has_key?(:disable_notification)

        # Allow custom JSON payload override (merge to allow overriding required fields if needed)
        if config.has_key?(:json)
          custom_json = evaluate_option(:json)
          custom_json.is_a?(Hash) ? payload.merge(custom_json) : custom_json
        else
          payload
        end
      end

      def raise_if_not_ok?
        value = evaluate_option(:raise_if_not_ok)
        value.nil? || value
      end

      def success?(response)
        if response.content_type == "application/json"
          JSON.parse(response.body).dig("ok") == true
        else
          response.is_a?(Net::HTTPSuccess)
        end
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_bulk_delivery_methods_telegram, Noticed::BulkDeliveryMethods::Telegram

