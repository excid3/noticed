module Noticed
  module DeliveryMethods
    class Kafka < DeliveryMethod
      required_options :url, :topic, :headers, :message

      def deliver
        topic = evaluate_option(:topic)
        url = [evaluate_option(:url), 'topics', topic].join('/')

        post_request url, headers: evaluate_option(:headers), json: evaluate_option(:message)
      rescue => e
        puts e.backtrace
      end
    end
  end
end
