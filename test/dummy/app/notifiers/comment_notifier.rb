class CommentNotifier < ApplicationNotifier
  deliver_by :test

  # delivery_by :email, mailer: "UserMailer", method: "new_comment"
  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :new_comment
  end

  deliver_by :action_cable do |config|
    config.channel = "Noticed::NotificationChannel"
    config.stream = -> { recipient }
    config.message = -> { params }
  end
end
