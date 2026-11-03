require "net/http"

module Noticed
  module ApiClient
    extend ActiveSupport::Concern

    FILTERED = ActiveSupport::ParameterFilter::FILTERED

    # Webhook URLs whose path carries the credential. The first group is kept and the second is
    # replaced with [FILTERED] in logs and error messages.
    #
    #   Discord          https://discord.com/api/webhooks/{id}/{token}[/slack|/github]
    #   Slack            https://hooks.slack.com/services/T000/B000/{token}
    #   Microsoft Teams  https://{tenant}.webhook.office.com/webhookb2/{group}@{tenant}/IncomingWebhook/{id}/{guid}[/V2/{guid}]
    URL_PATH_SECRETS = [
      %r{(/webhooks/\d+/)([^/]+)},
      %r{(/T[A-Z0-9]+/B[A-Z0-9]+/)([^/]+)},
      %r{(/webhookb2/[^/]+/IncomingWebhook/)(.+)}
    ].freeze

    # Query parameters filtered in addition to the application's `config.filter_parameters`.
    #
    #   Microsoft Teams Workflows  https://prod-00.westus.logic.azure.com/workflows/{id}/triggers/manual/paths/invoke?api-version=...&sp=...&sv=...&sig={secret}
    URL_QUERY_SECRETS = [:sig].freeze

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
      elsif (body = args.delete(:body))
        request.body = body
      end

      # Bodies aren't logged since they can contain credentials and access tokens,
      # and credentials in the URL are filtered
      logged_url = filtered_url(url)
      logger.debug("POST #{logged_url}")
      response = http.request(request)
      logger.debug("Response: #{response.code}")

      raise ResponseUnsuccessful.new(response, logged_url, args) unless response.code.start_with?("20")

      response
    end

    # Returns the URL with credentials replaced by [FILTERED], like Rails does for request parameters
    #
    #   filtered_url("https://discord.com/api/webhooks/123/abc?wait=true")
    #   # => "https://discord.com/api/webhooks/123/[FILTERED]?wait=true"
    def filtered_url(url)
      path, query = url.to_s.split("?", 2)

      if (pattern = URL_PATH_SECRETS.find { |regexp| path.match?(regexp) })
        path = path.sub(pattern) { "#{$1}#{FILTERED}" }
      end

      query ? "#{path}?#{filtered_query(query)}" : path
    end

    private

    def filtered_query(query)
      filters = Rails.application&.config&.filter_parameters.to_a + URL_QUERY_SECRETS
      parameter_filter = ActiveSupport::ParameterFilter.new(filters)

      query.split(/([&;])/).map do |part|
        key, value = part.split("=", 2)
        value ? "#{key}=#{parameter_filter.filter_param(key, value)}" : part
      end.join
    end
  end
end
