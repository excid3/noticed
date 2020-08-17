module Noticed
  module DeliveryMethods
    class Base < Noticed.parent_class.constantize
      extend ActiveModel::Callbacks
      define_model_callbacks :deliver

      attr_reader :notification, :options, :recipient, :record

      def perform(args)
        @notification = args[:notification_class].constantize.new(args[:params])
        @options = args[:options]
        @recipient = args[:recipient]
        @record = args[:record]

        # Make notification aware of database record and recipient during delivery
        @notification.record = args[:record]
        @notification.recipient = args[:recipient]

        run_callbacks :deliver do
          deliver
        end
      end

      def deliver
        raise NotImplementedError, "Delivery methods must implement a deliver method"
      end

      private

      # Helper method for making POST requests from delivery methods
      #
      # Usage:
      #   post("http://example.com", basic_auth: {user:, pass:}, json: {}, form: {})
      #
      def post(url, args = {})
        basic_auth = args.delete(:basic_auth)

        request = if basic_auth
          HTTP.basic_auth(user: basic_auth[:user], pass: basic_auth[:pass])
        else
          HTTP
        end

        response = request.post(url, args)

        if options[:debug]
          Rails.logger.debug("POST #{url}")
          Rails.logger.debug("Response: #{response.code}: #{response}")
        end

        if !options[:ignore_failure] && !response.status.success?
          raise ResponseUnsuccessful.new(response)
        end

        response
      end
    end
  end
end
