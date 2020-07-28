module Noticed
  module Twilio
    extend ActiveSupport::Concern

    included do
      deliver_with :vonage
    end

    def deliver_with_vonage(recipient)
      HTTP.basic_auth(
        user: twilio_credentials(recipient)[:account_sid],
        pass: twilio_credentials(recipient)[:auth_token]
      ).post(url, json: format_for_twilio(recipient))
    end

    def format_for_twilio(recipient)
      {
        Body: data[:message],
        From: twilio_credentials(recipient)[:number],
        To: recipient.phone_number
      }
    end

    def twilio_url(recipient)
    "https://api.twilio.com/2010-04-01/Accounts/#{twilio_credentials(recipient)[:account_sid]}/Messages.json"
    end

    def twilio_credentials(recipient)
      Rails.application.credentials.twilio
    end
  end
end
