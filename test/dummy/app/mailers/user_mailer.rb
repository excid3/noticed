class UserMailer < ApplicationMailer
  def comment_notification
    mail(body: "")
  end
end
