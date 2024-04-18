class UserMailer < ApplicationMailer
  def new_comment(*args)
    mail(body: "new comment")
  end

  def receipt
    mail(body: "receipt")
  end
end
