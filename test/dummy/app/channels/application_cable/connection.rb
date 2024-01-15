module ApplicationCable
  class Connection < ActionCable::Connection::Base
    def connect
      self.current_user = find_verified_user
      logger.add_tags "ActionCable", "User #{current_user.id}"
    end

    protected

    def find_verified_user
      if (current_user = env["warden"].user(:user))
        current_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
