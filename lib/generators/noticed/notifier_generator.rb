# frozen_string_literal: true

require "rails/generators/named_base"

module Noticed
  module Generators
    class NotifierGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      check_class_collision suffix: "Notifier"

      source_root File.expand_path("../templates", __FILE__)

      desc "Generates a notification with the given NAME."

      def generate_abstract_class
        return if File.exist?("app/notifiers/application_notifier.rb")
        template "application_notifier.rb", "app/notifiers/application_notifier.rb"
      end

      def generate_notification
        template "notifier.rb", "app/notifiers/#{file_path}_notifier.rb"
      end

      private

      def file_name # :doc:
        @_file_name ||= super.sub(/_notifier\z/i, "")
      end
    end
  end
end
