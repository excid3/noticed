module Noticed
  module DeliveryMethods
    class WebPush < Noticed::DeliveryMethods::Base
      def deliver
        recipient.web_push_subscriptions.each do |subscription|
          subscription.publish(notification.data)
        rescue ::WebPush::ExpiredSubscription
          Rails.logger.info "Removing expired WebPush subscription"
          subscription.destroy
        rescue ::WebPush::Unauthorized
          Rails.logger.info "Removing unauthorized WebPush subscription"
          subscription.destroy
        end
      end
    end
  end
end