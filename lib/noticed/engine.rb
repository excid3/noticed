module Noticed
  class Engine < ::Rails::Engine
    isolate_namespace Noticed

    initializer "noticed.has_notifications" do
      ActiveSupport.on_load(:active_record) do
        include Noticed::HasNotifications
      end
    end
  end
end
