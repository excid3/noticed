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
        generate :model, name, "recipient:references{polymorphic}", "type", params_column, "read_at:datetime", *attributes
      end

      def add_noticed_model
        inject_into_class model_path, class_name, "  include Noticed::Model\n"
      end

      def done
        readme "README" if behavior == :invoke
      end

      private

      def model_path
        @model_path ||= File.join("app", "models", "#{file_path}.rb")
      end

      def params_column
        case ActiveRecord::Base.connection.instance_values["config"][:adapter]
        when "mysql"
          "params:json"
        when "postgresql"
          "params:jsonb"
        else
          "params:text"
        end
      end
    end
  end
end
