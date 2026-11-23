# frozen_string_literal: true

require "rails/generators/named_base"

module Noticed
  module Generators
    class NotifierGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      check_class_collision suffix: "Notifier"

      source_root File.expand_path("../templates", __FILE__)

      desc "Generates a notification with the given NAME."

      class_option :parent, type: :string, default: "ApplicationNotifier", desc: "The parent class for the generated notifier"

      # ApplicationNotifier may be defined elsewhere, such as in an engine
      def generate_abstract_class
        return unless parent == "ApplicationNotifier"

        path = "app/notifiers/application_notifier.rb"
        return if parent.safe_constantize || File.exist?(File.join(destination_root, path))
        template "application_notifier.rb", path
      end

      def generate_notification
        template "notifier.rb", "app/notifiers/#{file_path}_notifier.rb"
      end

      private

      def file_name # :doc:
        @_file_name ||= super.sub(/_notifier\z/i, "")
      end

      def parent
        options[:parent]
      end
    end
  end
end
