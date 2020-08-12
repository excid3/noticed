class User < ApplicationRecord
  has_many :notifications, as: :recipient

  def phone_number
    "8675309"
  end
end
