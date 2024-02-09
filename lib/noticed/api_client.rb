require "net/http"

module Noticed
  module ApiClient
    extend ActiveSupport::Concern

    # Helper method for making POST requests from delivery methods
    #
    # Usage:
    #   post_request("http://example.com", basic_auth: {user:, pass:}, headers: {}, json: {}, form: {})
    #
    def post_request(url, args = {})
      args.compact!

      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.instance_of? URI::HTTPS

      headers = args.delete(:headers) || {}
      headers["Content-Type"] = "application/json" if args.has_key?(:json)

      request = Net::HTTP::Post.new(uri.request_uri, headers)

      if (basic_auth = args.delete(:basic_auth))
        request.basic_auth basic_auth.fetch(:user), basic_auth.fetch(:pass)
      end

      if (json = args.delete(:json))
        request.body = json.to_json
      elsif (form = args.delete(:form))
        request.form_data = form
      end

      logger.debug("POST #{url}")
      logger.debug(request.body)
      response = http.request(request)
      logger.debug("Response: #{response.code}: #{response.body.inspect}")

      raise ResponseUnsuccessful.new(response, url, args) unless response.code.start_with?("20")

      response
    end
  end
end
