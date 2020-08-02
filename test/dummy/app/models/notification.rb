class Notification < ApplicationRecord
  self.inheritance_column = nil

  serialize :params, Noticed::Coder

  belongs_to :recipient, polymorphic: true

  scope :sorted, -> { order(created_at: :desc) }

  def self.mark_as_read!
    update_all(read_at: Time.current, updated_at: Time.current)
  end

  # Rehydrate the database notification into the Notification object for rendering
  def to_instance
    @instance ||= begin
                    instance = type.constantize.new(params)
                    instance.record = self
                    instance
                  end
  end

  def mark_as_read!
    update(read_at: Time.current)
  end

  def unread?
    !read?
  end

  def read?
    read_at?
  end
end
