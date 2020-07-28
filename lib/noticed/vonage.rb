module Noticed
  module Vonage
    extend ActiveSupport::Concern

    included do
      deliver_with :vonage
    end

    def deliver_with_vonage(recipient)
      HTTP.post(
        "https://rest.nexmo.com/sms/json",
        json: format_for_vonage(recipient)
      )
    end

    def format_for_vonage(recipient)
      credentials = vonage_credentials(recipient)

      {
        api_key: credentials[:api_key],
        api_secret: credentials[:api_secret],
        from: data[:from],
        text: data[:body],
        to: data[:to],
        type: "unicode",
      }
    end

    def vonage_credentials(recipient)
      Rails.application.credentials.vonage
    end
  end
end
