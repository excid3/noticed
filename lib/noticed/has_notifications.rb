module Noticed
  module HasNotifications
    # Defines a method for the association and a before_destory callback to remove notifications
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
        model = options.fetch(:model_name, "Notification").constantize

        define_method "notifications_as_#{param_name}" do
          model.where(params: {param_name.to_sym => self})
        end

        if options.fetch(:destroy, true)
          before_destroy do
            send("notifications_as_#{param_name}").destroy_all
          end
        end
      end
    end
  end
end
