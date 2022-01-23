module Noticed
  module DeliveryMethods
    class Base < Noticed.parent_class.constantize
      extend ActiveModel::Callbacks
      define_model_callbacks :deliver

      class_attribute :option_names, instance_writer: false, default: []

      attr_reader :notification, :options, :params, :recipient, :record

      class << self
        # Copy option names from parent
        def inherited(base) # :nodoc:
          base.option_names = option_names.dup
          super
        end

        def options(*names)
          option_names.concat Array.wrap(names)
        end
        alias_method :option, :options

        def validate!(delivery_method_options)
          option_names.each do |option_name|
            unless delivery_method_options.key? option_name
              raise ValidationError, "option `#{option_name}` must be set for #{name}"
            end
          end
        end
      end

      def assign_args(args)
        @notification = args.fetch(:notification_class).constantize.new(args[:params])
        @options = args[:options] || {}
        @params = args[:params]
        @recipient = args[:recipient]
        @record = args[:record]

        # Make notification aware of database record and recipient during delivery
        @notification.record = args[:record]
        @notification.recipient = args[:recipient]
        self
      end

      def perform(args)
        assign_args(args)

        return if (condition = @options[:if]) && !@notification.send(condition)
        return if (condition = @options[:unless]) && @notification.send(condition)

        run_callbacks :deliver do
          deliver
        end
      end

      def deliver
        raise NotImplementedError, "Delivery methods must implement a deliver method"
      end

      private

      def build_default_connection(args)
        basic_auth = args.delete(:basic_auth)
        headers = Faraday::Utils::Headers.new(args.delete(:headers) || {})
        Faraday.new do |connection|
          connection.headers["Content-Type"] = "application/json" if args[:json]
          connection.headers["Content-Type"] = "application/x-www-form-urlencoded" if args[:form]
          headers.each do |header, value|
            connection.headers[header] = value
          end
          connection.request :basic_auth, basic_auth[:user], basic_auth[:pass] if basic_auth
        end
      end

      # Helper method for making POST requests from delivery methods
      #
      # Usage:
      #   post("http://example.com", basic_auth: {user:, pass:}, headers: {}, json: {}, form: {})
      #
      def post(url, args = {})
        options ||= {}
        connection = respond_to?(:build_connection) ? connection(args) : build_default_connection(args)
        response = connection.post(url) do |request|
          request.body = if args[:json]
            args[:json].to_json
          elsif args[:form]
            URI.encode_www_form(args[:form])
          else
            ""
          end
        end

        if options[:debug]
          Rails.logger.debug("POST #{url}")
          Rails.logger.debug("Response: #{response.status}: #{response.body}")
        end

        if !options[:ignore_failure] && !response.success?
          puts response.status
          puts response.body
          raise ResponseUnsuccessful.new(response)
        end

        response
      end
    end
  end
end
