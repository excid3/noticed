class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com", to: "to@example.com"
  layout "mailer"
end
