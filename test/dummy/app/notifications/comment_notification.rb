class CommentNotification < Noticed::Base
  deliver_by :database do |config|
    config.format = proc do
      {
        account_id: 1,
        type: self.class.name,
        params: params
      }
    end
  end

  deliver_by :action_cable

  deliver_by :email do |config|
    config.mailer = "UserMailer"
  end

  deliver_by :discord, class: "DiscordNotification"

  def url
    root_url
  end
end
