module Noticed
  module DeliveryMethods
    class Ios < Base
      option :app_name

      def deliver
        app = Rpush::Apnsp8::App.find_by_name!(options[:app_name])

        device_tokens.each do |device_token|
          n = Rpush::Apnsp8::Notification.new
          n.app = app
          n.device_token = device_token
          if (method = options[:format])
            n = notification.send(method, n)
          else
            n.alert = params[:message]
          end
          n.save!
        end
      end

      private

      def device_tokens
        notification.ios_device_tokens(recipient)
      end
    end
  end
end
