class UserMailer < ApplicationMailer
  def new_comment(*args)
    mail(body: "new comment")
  end

  def greeting(message = "message", body:, subject: "Hello")
    mail(body: body, subject: subject)
  end

  def receipt
    mail(body: "receipt")
  end
end
