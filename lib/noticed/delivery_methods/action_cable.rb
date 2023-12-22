module Noticed
  module DeliveryMethods
    class ActionCable < DeliveryMethod
      required_options :channel, :stream, :message

      def deliver
        channel = fetch_constant(:channel)
        stream = evaluate_option(:stream)
        message = evaluate_option(:message)

        channel.broadcast_to stream, message
      end
    end
  end
end
