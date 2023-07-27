class UserMailer < ApplicationMailer
  def comment_notification
    mail(body: "")
  end

  def comment_notification_for(_user)
    mail(body: "")
  end
end
