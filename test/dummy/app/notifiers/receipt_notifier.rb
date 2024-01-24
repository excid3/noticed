class ReceiptNotifier < ApplicationNotifier
  deliver_by :test

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :receipt
    config.params = -> { params }
  end
end
