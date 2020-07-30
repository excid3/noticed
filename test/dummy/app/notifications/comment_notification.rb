class CommentNotification < Noticed::Base
  deliver_by :database, format_with: :attributes_for_database
  deliver_by :websocket
  deliver_by :email, mailer: UserMailer
  # deliver_by DiscordNotification

  def attributes_for_database
    params.merge({
      account_id: recipient.email
    })
  end
end
