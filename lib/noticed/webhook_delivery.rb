module Noticed
  # Shared between the individual and bulk Webhook delivery methods
  module WebhookDelivery
    extend ActiveSupport::Concern

    included do
      required_options :url
    end

    def deliver
      post_request(
        evaluate_option(:url),
        basic_auth: evaluate_option(:basic_auth),
        headers: evaluate_option(:headers),
        json: evaluate_option(:json),
        form: evaluate_option(:form),
        body: evaluate_option(:body)
      )
    end
  end
end
