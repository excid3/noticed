# frozen_string_literal: true

require "rails/generators/named_base"

module Noticed
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      source_root File.expand_path("../templates", __FILE__)

      desc "Generates a Notification model for storing notifications."

      argument :name, type: :string, default: "Notification", banner: "Notification"
      argument :attributes, type: :array, default: [], banner: "field:type field:type"

      def generate_notification
        generate :model, name, "recipient:references{polymorphic}", "type", params_column, "read_at:datetime:index", *attributes
      end

      def add_noticed_model
        inject_into_class model_path, class_name, "  include Noticed::Model\n"
      end

      def add_not_nullable
        migration_path = Dir.glob(Rails.root.join("db/migrate/*")).max_by { |f| File.mtime(f) }

        # Force is required because null: false already exists in the file and Thor isn't smart enough to tell the difference
        insert_into_file migration_path, after: "t.string :type", force: true do
          ", null: false"
        end
      end

      def done
        readme "README" if behavior == :invoke
      end

      private

      def model_path
        @model_path ||= File.join("app", "models", "#{file_path}.rb")
      end

      def params_column
        case current_adapter
        when "postgresql", "postgis"
          "params:jsonb"
        else
          # MySQL and SQLite both support json
          "params:json"
        end
      end

      def current_adapter
        if ActiveRecord::Base.respond_to?(:connection_db_config)
          ActiveRecord::Base.connection_db_config.adapter
        else
          ActiveRecord::Base.connection_config[:adapter]
        end
      end
    end
  end
end
