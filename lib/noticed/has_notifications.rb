module Noticed
  module HasNotifications
    # Defines a method for the association and a before_destroy callback to remove notifications
    # where this record is a param
    #
    #    class User < ApplicationRecord
    #      has_noticed_notifications
    #      has_noticed_notifications param_name: :owner, destroy: false, model: "Notification"
    #    end
    #
    #    @user.notifications_as_user
    #    @user.notifications_as_owner

    extend ActiveSupport::Concern

    class_methods do
      def has_noticed_notifications(param_name: model_name.singular, **options)
        define_method "notifications_as_#{param_name}" do
          model = options.fetch(:model_name, "Notification").constantize
          case current_adapter
          when "postgresql", "postgis"
            model.where("params @> ?", Noticed::Coder.dump(param_name.to_sym => self).to_json)
          when "mysql2"
            model.where("JSON_CONTAINS(params, ?)", Noticed::Coder.dump(param_name.to_sym => self).to_json)
          when "sqlite3"
            model.where("json_extract(params, ?) = ?", "$.#{param_name}", Noticed::Coder.dump(self).to_json)
          else
            # This will perform an exact match which isn't ideal
            model.where(params: {param_name.to_sym => self})
          end
        end

        if options.fetch(:destroy, true)
          before_destroy do
            send("notifications_as_#{param_name}").destroy_all
          end
        end
      end
    end

    def current_adapter
      if ActiveRecord::Base.respond_to?(:connection_db_config)
        ActiveRecord::Base.connection_db_config.adapter
      else
        ActiveRecord::Base.connection_config[:adapter]
      end
    end
  end
end
