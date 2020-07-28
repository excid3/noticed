module Noticed
  module Slack
    extend ActiveSupport::Concern

    included do
      deliver_with :slack
    end

    def deliver_with_slack(recipient)
      HTTP.post(slack_url(recipient), json: format_for_slack(recipient))
    end

    def format_for_slack(recipient)
      data
    end

    def slack_url(recipient)
      Rails.application.credentials.slack[:notification_url]
    end
  end
end
