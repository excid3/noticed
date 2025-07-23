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
          template "application_bulk_delivery_method.rb", "app/notifiers/application_bulk_delivery_method.rb"
          template "bulk_delivery_method.rb", "app/notifiers/bulk_delivery_methods/#{singular_name}.rb"
        else
          template "application_delivery_method.rb", "app/notifiers/application_delivery_method.rb"
          template "delivery_method.rb", "app/notifiers/delivery_methods/#{singular_name}.rb"
        end
      end
    end
  end
end
