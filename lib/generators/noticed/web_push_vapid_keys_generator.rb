# frozen_string_literal: true

require "rails/generators/named_base"

module Noticed
  module Generators
    class WebPushVapidKeysGenerator < Rails::Generators::Base
      def generate_vapid_keys
        puts <<~KEYS
          Add the following to your credentials (rails credentials:edit):"

          web_push:
            public_key: "#{vapid_key.public_key}"
            private_key: "#{vapid_key.private_key}"
        KEYS
      end

      private

      def vapid_key
        @vapid_key ||= WebPush.generate_key
      end
    end
  end
end
