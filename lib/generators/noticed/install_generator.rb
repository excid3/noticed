# frozen_string_literal: true

module Noticed
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      desc "Copies the Noticed migrations into your application."

      def create_migrations
        rails_command "railties:install:migrations FROM=noticed", inline: true
      end

      def done
        readme "README" if behavior == :invoke
      end
    end
  end
end
