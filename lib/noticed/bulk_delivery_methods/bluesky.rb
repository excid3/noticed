module Noticed
  module BulkDeliveryMethods
    class Bluesky < BulkDeliveryMethod
      required_options :identifier, :password, :json

      # bulk_deliver_by :bluesky do |config|
      #   config.identifier = ENV["BLUESKY_ID"]
      #   config.password = ENV["BLUESKY_PASSWORD"]
      #   config.json = {text: "...", createdAt: "..."}
      # end

      def deliver
        Rails.logger.debug(evaluate_option(:json))
        post_request(
          "https://#{host}/xrpc/com.atproto.repo.createRecord",
          headers: {"Authorization" => "Bearer #{token}"},
          json: {
            repo: identifier,
            collection: "app.bsky.feed.post",
            record: evaluate_option(:json)
          }
        )
      end

      def token
        start_session.dig("accessJwt")
      end

      def start_session
        response = post_request(
          "https://#{host}/xrpc/com.atproto.server.createSession",
          json: {
            identifier: identifier,
            password: evaluate_option(:password)
          }
        )
        JSON.parse(response.body)
      end

      def host
        @host ||= evaluate_option(:host) || "bsky.social"
      end

      def identifier
        @identifier ||= evaluate_option(:identifier)
      end
    end
  end
end
