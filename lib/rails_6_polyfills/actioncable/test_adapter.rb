# frozen_string_literal: true

require "action_cable/subscription_adapter/base"
require "action_cable/subscription_adapter/subscriber_map"
require "action_cable/subscription_adapter/async"

module ActionCable
  module SubscriptionAdapter
    # == Test adapter for Action Cable
    #
    # The test adapter should be used only in testing. Along with
    # <tt>ActionCable::TestHelper</tt> it makes a great tool to test your Rails application.
    #
    # To use the test adapter set +adapter+ value to +test+ in your +config/cable.yml+ file.
    #
    # NOTE: Test adapter extends the <tt>ActionCable::SubscriptionsAdapter::Async</tt> adapter,
    # so it could be used in system tests too.
    class Test < Async
      def broadcast(channel, payload)
        broadcasts(channel) << payload
        super
      end

      def broadcasts(channel)
        channels_data[channel] ||= []
      end

      def clear_messages(channel)
        channels_data[channel] = []
      end

      def clear
        @channels_data = nil
      end

      private

      def channels_data
        @channels_data ||= {}
      end
    end
  end

  # Update how broadcast_for determines the channel name so it's consistent with the Rails 6 way
  module Channel
    module Broadcasting
      delegate :broadcast_to, to: :class
      module ClassMethods
        def broadcast_to(model, message)
          ActionCable.server.broadcast(broadcasting_for(model), message)
        end

        def broadcasting_for(model)
          serialize_broadcasting([channel_name, model])
        end

        def serialize_broadcasting(object) # :nodoc:
          case # standard:disable Style/EmptyCaseCondition
          when object.is_a?(Array)
            object.map { |m| serialize_broadcasting(m) }.join(":")
          when object.respond_to?(:to_gid_param)
            object.to_gid_param
          else
            object.to_param
          end
        end
      end
    end
  end
end
