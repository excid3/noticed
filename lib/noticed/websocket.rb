module Noticed
  module Websocket
    extend ActiveSupport::Concern

    included do
      deliver_with :websocket
    end

    def deliver_with_websocket(recipient)
      websocket_channel.broadcast_to recipient, format_for_websocket(recipient)
    end

    def format_for_websocket(recipient)
      data
    end

    def websocket_channel
      NotificationChannel
    end
  end
end

