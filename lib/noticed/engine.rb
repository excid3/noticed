module Noticed
  class Engine < ::Rails::Engine
    initializer "noticed.has_notifications" do
      ActiveSupport.on_load(:active_record) do
        include Noticed::HasNotifications
      end
    end

    initializer "noticed.rails_5_2_support" do
      require "rails_6_polyfills/base" if Rails::VERSION::MAJOR < 6
    end
  end
end
