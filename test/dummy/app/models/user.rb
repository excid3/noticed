class User < ApplicationRecord
  has_many :notifications, as: :recipient

  has_noticed_notifications
  has_noticed_notifications param_name: :owner, destroy: false

  def phone_number
    "8675309"
  end
end
