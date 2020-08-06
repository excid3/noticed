class JsonNotification < ApplicationRecord
  include Noticed::Model
  self.table_name = "json_notifications"
end
