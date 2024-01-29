class AddNotificationsCountToNoticedEvent < ActiveRecord::Migration[7.1]
  def change
    add_column :noticed_events, :notifications_count, :integer
  end
end
