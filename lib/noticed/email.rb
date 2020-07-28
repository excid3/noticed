module Noticed
  module Email
    extend ActiveSupport::Concern

    included do
      deliver_with :email
    end

    def deliver_with_email(recipient)
      name = self.class.to_s.underscore
      NotificationMailer.with(self).send(name.to_sym).deliver_later
    end
  end
end
