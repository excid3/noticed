# frozen_string_literal: true

module Noticed
  module Generators
    class ModelGenerator < Rails::Generators::Base
      include Rails::Generators::ResourceHelpers

      source_root File.expand_path("../templates", __FILE__)

      def create_migrations
        rails_command "railties:install:migrations FROM=noticed", inline: true
      end

      def done
        readme "README" if behavior == :invoke
      end
    end
  end
end
