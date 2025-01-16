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
      def mark_as_read_and_seen(**kwargs)
        update_all(**kwargs.with_defaults(read_at: Time.current, seen_at: Time.current, updated_at: Time.current))
      end

      def mark_as_unread_and_unseen(**kwargs)
        update_all(**kwargs.with_defaults(read_at: nil, seen_at: nil, updated_at: Time.current))
      end

      def mark_as_read(**kwargs)
        update_all(**kwargs.with_defaults(read_at: Time.current, updated_at: Time.current))
      end

      def mark_as_unread(**kwargs)
        update_all(**kwargs.with_defaults(read_at: nil, updated_at: Time.current))
      end

      def mark_as_seen(**kwargs)
        update_all(**kwargs.with_defaults(seen_at: Time.current, updated_at: Time.current))
      end

      def mark_as_unseen(**kwargs)
        update_all(**kwargs.with_defaults(seen_at: nil, updated_at: Time.current))
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
