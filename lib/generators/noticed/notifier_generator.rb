# frozen_string_literal: true

require "rails/generators/named_base"

module Noticed
  module Generators
    class NotifierGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      source_root File.expand_path("../templates", __FILE__)

      desc "Generates a notifier with the given NAME."

      def generate_notification
        template "notifier.rb", "app/notifications/#{file_path}.rb"
      end
    end
  end
end
