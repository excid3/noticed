require 'minitest/mock'
require 'minitest/stub_any_instance'

module Noticed
  module DeliveryMethods
    class SlackMessage < Base
      URL = "https://slack.com/api/chat.postMessage"

      def self.stub_success_response(&block)
        response = MiniTest::Mock.new
        response.expect :body, '{"ok": true}'

        SlackMessage.stub_any_instance :post, response do
          yield block
        end
      end

      def deliver
        uri = URI.parse(URL)

        response = post(uri,
          bearer_auth: {token: token},
          headers: {"Content-Type" => "application/json; charset=utf-8"},
          body: format.merge(channel: channel).to_json)

        result = JSON.parse(response.body)

        if result["ok"] != true
          raise ResponseUnsuccessful, result["error"]
        elsif options[:on_success]
          notification.send(options[:on_success], result)
        end

        response
      end

      private

      def post(uri, args = {})
        options ||= {}
        basic_auth = args.delete(:basic_auth)
        bearer_auth = args.delete(:bearer_auth)

        headers = args.delete(:headers)

        body = args.delete(:body)

        req = Net::HTTP::Post.new(uri.to_s)

        req["Authorization"] = basic_auth_header(basic_auth) if basic_auth
        req["Authorization"] = bearer_auth_header(bearer_auth) if bearer_auth

        headers&.each do |header, value|
          req[header] = value
        end

        req.body = body if body

        response = https(uri).request(req)

        if options[:debug]
          Rails.logger.debug("POST #{uri}")
          Rails.logger.debug("Response: #{response.code}: #{response}")
        end

        if !options[:ignore_failure] && !response.is_a?(Net::HTTPSuccess)
          raise ResponseUnsuccessful.new(response)
        end

        response
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
        Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
        raise ResponseUnsuccessful, e
      end

      def https(uri)
        Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end

      def basic_auth_header(args)
        "Basic #{Base64.encode64(basic_auth[:user] + ":" + basic_auth[:pass])}"
      end

      def bearer_auth_header(args)
        "Bearer #{args[:token]}"
      end

      def token
        if notification.respond_to?(:slack_token)
          notification.slack_token
        else
          raise NoMethodError, <<~MESSAGE
            You must implement `slack_token` to send Slack Message notifications

            # This must return a valid Slack API token
            def slack_token
              recipient.slack_authorization.token
            end
          MESSAGE
        end
      end

      def channel
        if notification.respond_to?(:slack_channel)
          notification.slack_channel
        else
          raise NoMethodError, <<~MESSAGE
            You must implement `slack_channel` to send Slack Message notifications

            # This must return a valid channel, private group, or IM channel ID to send message to
            def slack_channel
              recipient.slack_authorization.user_id
            end
          MESSAGE
        end
      end

      def format
        if (method = options[:format])
          notification.send(method)
        else
          notification.params
        end
      end
    end
  end
end
