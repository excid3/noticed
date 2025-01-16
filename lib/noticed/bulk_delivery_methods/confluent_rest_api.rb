module Noticed
  module BulkDeliveryMethods
    class ConfluentRestApi < BulkDeliveryMethod
      required_options :url, :headers, :message

      def deliver
        url = evaluate_option(:url)
        message = evaluate_option(:message)

        json = {
          key: {
            type: 'STRING',
            data: message[:key]
          },
          value: {
            type: 'JSON',
            data: message[:value]
          }
        }

        post_request url, headers: evaluate_option(:headers), json: json
      end
    end
  end
end
