module Noticed
  module RequiredOptions
    extend ActiveSupport::Concern

    included do
      class_attribute :required_option_names, instance_writer: false, default: []
    end

    class_methods do
      def inherited(base)
        base.required_option_names = required_option_names.dup
        super
      end

      def required_options(*names)
        required_option_names.concat names
      end
      alias_method :required_option, :required_options
    end
  end
end
