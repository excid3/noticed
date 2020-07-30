class User < ApplicationRecord
  has_many :notifications, as: :recipient
end
