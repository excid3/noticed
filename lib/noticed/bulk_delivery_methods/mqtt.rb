# frozen_string_literal: true

require 'aws-sdk-iotdataplane'
require 'mqtt'

module Noticed
  module BulkDeliveryMethods
    class Mqtt < BulkDeliveryMethod
      DEFAULT_MQTT_PORTS = { mqtt: 1883, mqtts: 8883 }.freeze
      DEFAULT_QOS_RANGE = (0..2)
      AWS_IOT_QOS_RANGE = (0..1)

      required_options :provider, :url, :message

      def deliver
        provider = evaluate_option(:provider).to_s
        endpoint = evaluate_option(:url)
        message  = evaluate_option(:message)

        case provider
        when 'aws_iot'
          publish_via_aws_iot(endpoint, message)
        else
          publish_via_mqtt_broker(endpoint, message)
        end
      end

      private

      def publish_via_aws_iot(endpoint, message)
        credentials = evaluate_option(:credentials)

        client = Aws::IoTDataPlane::Client.new(
          endpoint:,
          region: credentials[:region],
          credentials: Aws::Credentials.new(credentials[:access_key_id], credentials[:secret_access_key])
        )

        client.publish(
          topic: message.fetch(:topic),
          payload: serialise_payload(message.fetch(:payload)),
          qos: messamessage.fetch(:qos, 0).to_i.clamp(*AWS_IOT_QOS_RANGE),
          retain: message.fetch(:retain, false)
        )
      end

      def publish_via_mqtt_broker(endpoint, message)
        host, port, tls = parse_url(endpoint)
        credentials = evaluate_option(:credentials)

        params = {
          host:,
          port:,
          client_id:,
          ssl: tls,
          username: credentials[:username],
          password: credentials[:password]
        }

        MQTT::Client.connect(**params) do |client|
          client.publish(
            message.fetch(:topic),
            serialise_payload(message.fetch(:payload)),
            message.fetch(:retain, false),
            message.fetch(:qos, 0).to_i.clamp(*DEFAULT_QOS_RANGE)
          )
        end
      end

      def parse_url(raw)
        uri = URI(raw.include?('://') ? raw : "mqtt://#{raw}")

        host = uri.host
        port = uri.port || DEFAULT_MQTT_PORTS[uri.scheme&.to_sym] || 1883
        tls = uri.scheme == 'mqtts'

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
