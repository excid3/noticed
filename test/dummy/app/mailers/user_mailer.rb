class UserMailer < ApplicationMailer
  def comment_notifier
    mail(body: "")
  end
end
