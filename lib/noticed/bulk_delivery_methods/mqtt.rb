module Noticed
  module BulkDeliveryMethods
    class Mqtt < BulkDeliveryMethod
      required_options :url, :message

      def deliver
        host, port, tls = parse_url(evaluate_option(:url))
        message = evaluate_option(:message)

        params = {
          host: host,
          port: port,
          client_id: client_id,
          ssl: tls
        }.merge(auth_opts)

        MQTT::Client.connect(**params) do |client|
          client.publish(
            message.fetch(:topic),
            serialise_payload(message.fetch(:payload)),
            message.fetch(:retain, false),
            message.fetch(:qos, 0).to_i.clamp(0, 2)
          )
        end
      end

      private

      def auth_opts
        case evaluate_option(:provider).to_sym
        when :emqx
          basic_auth = evaluate_option(:basic_auth)
          {
            username: basic_auth[:user],
            password: basic_auth[:pass]
          }
        else
          basic_auth = evaluate_option(:basic_auth)
          {
            username: basic_auth[:user],
            password: basic_auth[:pass]
          }
        end
      end

      def parse_url(raw)
        raw = "mqtt://#{raw}" unless raw[%r{^\w+://}]
        uri = URI(raw)

        host = uri.host
        port = uri.port || (uri.scheme == "mqtts" ? 8883 : 1883)
        tls = (uri.scheme == "mqtts") || port == 8883

        [host, port, tls]
      end

      def serialise_payload(payload)
        payload.is_a?(String) ? payload : payload.to_json
      end

      def client_id
        "okya-notice-#{SecureRandom.hex(4)}"
      end
    end
  end
end
