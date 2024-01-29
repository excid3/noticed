class User < ApplicationRecord
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"

  # Used for querying Noticed::Event where params[:user] is a User instance
  has_noticed_notifications
  has_noticed_notifications param_name: :owner, destroy: false
end
