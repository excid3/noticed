class CommentNotification < Noticed::Base
  deliver_by :database, format: :attributes_for_database
  deliver_by :action_cable
  deliver_by :email, mailer: "UserMailer"
  deliver_by :discord, class: "DiscordNotification"

  def attributes_for_database
    params.merge({
      account_id: 1
    })
  end
end
