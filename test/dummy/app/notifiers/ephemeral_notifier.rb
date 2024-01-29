class EphemeralNotifier < Noticed::Ephemeral
  bulk_deliver_by :test

  deliver_by :test do |config|
    config.wait = 5.minutes
  end

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "new_comment"
    config.args = :email_args
    config.params = -> { {recipient: recipient} }
  end

  def email_args(recipient)
    [recipient]
  end
end
