class CommentNotifier < Noticed::Event
  required_params :message

  deliver_by :test

  # delivery_by :email, mailer: "UserMailer", method: "new_comment"
  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :new_comment
    # config.params = -> { params }
    # config.args = -> { recipient }
  end

  deliver_by :action_cable do |config|
    config.channel = "NotificationChannel"
    config.stream = -> { recipient }
    config.message = -> { params }
  end

  deliver_by :twilio_messaging do |config|
    config.phone_number = "+1234567890"
    config.account_sid = "abcd1234"
    config.auth_token = "secret"
  end

  deliver_by :microsoft_teams do |config|
    config.url = "https://example.org"
    config.json = -> { params }
  end

  deliver_by :slack do |config|
    config.headers = {"Authorization" => "Bearer xoxb-xxxxxxxxx-xxxxxxxxxx"}
    config.json = -> { params }
  end

  deliver_by :fcm do |config|
    config.credentials = Rails.root.join("config/certs/fcm.json")
    # Or store them in the Rails credentials
    # config.credentials = Rails.application.credentials.fcm
    config.device_tokens = -> { recipient.device_tokens }

    config.json = ->(device_token) {
      {
        token: device_token,
        notification: {
          title: "Test Title",
          body: "Test body"
        }
      }
    }

    # Clean up invalid tokens that are no longer usable
    config.invalid_token = ->(token:, platform:) { recipient.device_tokens.where(id: token.id).destroy_all }
  end

  deliver_by :ios do |config|
  end
end
