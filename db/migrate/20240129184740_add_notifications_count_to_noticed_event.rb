class AddNotificationsCountToNoticedEvent < ActiveRecord::Migration[7.1]
  def change
    add_column :noticed_events, :notifications_count, :integer, if_not_exists: true
  end
end
