class JsonbNotification < ApplicationRecord
  include Noticed::Model
  self.table_name = "jsonb_notifications"
end
