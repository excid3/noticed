module Noticed
  module DeliveryMethods
    class Kafka < DeliveryMethod
      required_options :client_id, :brokers, :authentication_method, :username, :password, :topic, :message

      def deliver
        topic = evaluate_option(:topic)
        message = evaluate_option(:message)

        producer.produce_async(topic: topic, payload: message.to_json)
      ensure
        producer.shutdown
      end

      def producer
        client_id = evaluate_option(:client_id)
        brokers = evaluate_option(:brokers)

        WaterDrop::Producer.new do |config|
          config.deliver = true
          config.kafka = {
            'client.id': client_id,
            'bootstrap.servers': brokers.split(','),
            'request.required.acks': 1
          }
        end
      end
    end

    def settings
      {
        'bootstrap.servers': evaluate_option(:brokers),
        'sasl.mechanism': 'PLAIN',
        'security.protocol': 'SASL_PLAINTEXT',
        'sasl.username': ENV.fetch('KAFKA_USERNAME', 'default'),
        'sasl.password': ENV.fetch('KAFKA_PASSWORD', 'default')
      }
    end
  end
end
