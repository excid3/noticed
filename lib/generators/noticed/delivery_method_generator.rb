# frozen_string_literal: true

require "rails/generators/named_base"

module Noticed
  module Generators
    class DeliveryMethodGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      source_root File.expand_path("../templates", __FILE__)

      desc "Generates a class for a custom delivery method with the given NAME."

      class_option :bulk, desc: "Generate as a bulk delivery method", type: :boolean, default: false

      def generate_notification
        if options[:bulk]
          generate_abstract_class "ApplicationBulkDeliveryMethod"
          template "bulk_delivery_method.rb", "app/notifiers/bulk_delivery_methods/#{singular_name}.rb"
        else
          generate_abstract_class "ApplicationDeliveryMethod"
          template "delivery_method.rb", "app/notifiers/delivery_methods/#{singular_name}.rb"
        end
      end

      private

      # The abstract class may be defined elsewhere, such as in an engine
      def generate_abstract_class(name)
        path = "app/notifiers/#{name.underscore}.rb"
        return if name.safe_constantize || File.exist?(File.join(destination_root, path))
        template "#{name.underscore}.rb", path
      end
    end
  end
end
