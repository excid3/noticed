module Noticed
  module Model
    DATABASE_ERROR_CLASS_NAMES = lambda {
      classes = [ActiveRecord::NoDatabaseError]
      classes << ActiveRecord::ConnectionNotEstablished
      classes << Mysql2::Error if defined?(::Mysql2)
      classes << PG::ConnectionBad if defined?(::PG)
      classes
    }.call.freeze

    extend ActiveSupport::Concern

    included do
      self.inheritance_column = nil

      if Rails.gem_version >= Gem::Version.new("7.1.0.alpha")
        serialize :params, coder: noticed_coder
      else
        serialize :params, noticed_coder
      end

      belongs_to :recipient, polymorphic: true

      scope :newest_first, -> { order(created_at: :desc) }
      scope :unread, -> { where(read_at: nil) }
      scope :read, -> { where.not(read_at: nil) }
    end

    class_methods do
      def mark_as_read!
        update_all(read_at: Time.current, updated_at: Time.current)
      end

      def mark_as_unread!
        update_all(read_at: nil, updated_at: Time.current)
      end

      def noticed_coder
        return Noticed::TextCoder unless table_exists?

        case attribute_types["params"].type
        when :json, :jsonb
          Noticed::Coder
        else
          Noticed::TextCoder
        end
      rescue *DATABASE_ERROR_CLASS_NAMES => _error
        warn("Noticed was unable to bootstrap correctly as the database is unavailable.")

        Noticed::TextCoder
      end
    end

    # Rehydrate the database notification into the Notification object for rendering
    def to_notification
      @_notification ||= begin
        instance = type.constantize.with(params)
        instance.record = self
        instance.recipient = recipient
        instance
      end
    end

    def mark_as_read!
      update(read_at: Time.current)
    end

    def mark_as_unread!
      update(read_at: nil)
    end

    def unread?
      !read?
    end

    def read?
      read_at?
    end

    # If a GlobalID record in params is no longer found, the params will default with a noticed_error key
    def deserialize_error?
      !!params[:noticed_error]
    end
  end
end
