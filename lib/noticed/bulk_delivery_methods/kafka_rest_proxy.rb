module Noticed
  module BulkDeliveryMethods
    class KafkaRestProxy < BulkDeliveryMethod
      required_options :url, :headers, :message

      def deliver
        url = evaluate_option(:url)
        message = evaluate_option(:message)

        json = { records: [{ key: message[:key], value: message[:value] }] }

        post_request url, headers: evaluate_option(:headers), json: json
      end
    end
  end
end
