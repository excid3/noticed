require "net/http"

module Noticed
  module ApiClient
    extend ActiveSupport::Concern

    # Webhook URLs whose path carries the credential. The first group is kept and the second is
    # replaced with [FILTERED] in logs and error messages.
    #
    #   Discord          https://discord.com/api/webhooks/{id}/{token}[/slack|/github]
    #   Slack            https://hooks.slack.com/services/T000/B000/{token}
    #   Microsoft Teams  https://{tenant}.webhook.office.com/webhookb2/{group}@{tenant}/IncomingWebhook/... (everything after is filtered)
    CREDENTIAL_PATHS = [
      %r{(/webhooks/\d+/)([^/]+)},
      %r{(hooks\.slack\.com/(?:services/)?T[^/]+/B[^/]+/)([^/]+)},
      %r{(/webhookb2/[^/]+/IncomingWebhook/)(.+)}
    ]

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

      # Bodies aren't logged since they can contain credentials and access tokens
      logger.debug("POST #{ApiClient.filtered_url(url)}")
      response = http.request(request)
      logger.debug("Response: #{response.code}")

      raise ResponseUnsuccessful.new(response, url, args) unless response.code.start_with?("20")

      response
    end

    # Returns the URL with credentials replaced by [FILTERED], like Rails does for request parameters
    #
    #   Noticed::ApiClient.filtered_url("https://discord.com/api/webhooks/123/abc?wait=true")
    #   # => "https://discord.com/api/webhooks/123/[FILTERED]?wait=true"
    def self.filtered_url(url)
      path, query = url.to_s.split("?", 2)
      CREDENTIAL_PATHS.each { |pattern| path = path.sub(pattern) { "#{$1}[FILTERED]" } }

      if query
        # Application's filter_parameters plus sig, the secret of Microsoft Teams Workflows URLs:
        # https://prod-00.westus.logic.azure.com/workflows/{id}/triggers/manual/paths/invoke?api-version=...&sp=...&sv=...&sig={secret}
        parameter_filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters + [:sig])
        query = query.gsub(/([^&=]+)=([^&]*)/) { "#{$1}=#{parameter_filter.filter_param($1, $2)}" }
      end

      query ? "#{path}?#{query}" : path
    end
  end
end
