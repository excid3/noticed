module Noticed
  module Readable
    extend ActiveSupport::Concern

    included do
      scope :read, -> { where.not(read_at: nil) }
      scope :unread, -> { where(read_at: nil) }
      scope :seen, -> { where.not(seen_at: nil) }
      scope :unseen, -> { where(seen_at: nil) }
    end

    class_methods do
      def mark_as_read
        update_all(read_at: Time.current, updated_at: Time.current)
      end

      def mark_as_unread
        update_all(read_at: nil, updated_at: Time.current)
      end

      def mark_as_seen
        update_all(seen_at: Time.current, updated_at: Time.current)
      end

      def mark_as_unseen
        update_all(seen_at: nil, updated_at: Time.current)
      end
    end

    def mark_as_read
      update(read_at: Time.current)
    end

    def mark_as_read!
      update!(read_at: Time.current)
    end

    def mark_as_unread
      update(read_at: nil)
    end

    def mark_as_unread!
      update!(read_at: nil)
    end

    def mark_as_seen
      update(seen_at: Time.current)
    end

    def mark_as_seen!
      update!(seen_at: Time.current)
    end

    def mark_as_unseen
      update(seen_at: nil)
    end

    def mark_as_unseen!
      update!(seen_at: nil)
    end

    def read?
      read_at?
    end

    def unread?
      !read_at?
    end

    def seen?
      seen_at?
    end

    def unseen?
      !seen_at?
    end
  end
end
