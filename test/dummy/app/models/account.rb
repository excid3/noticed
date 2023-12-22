class Account < ApplicationRecord
  has_many :notifications, as: :record, dependent: :destroy, class_name: "Noticed::Notification"
  has_many :notifiers, as: :record, dependent: :destroy, class_name: "Noticed::Event"
end
