class SimpleNotifier < ApplicationNotifier
  deliver_by :test
  required_params :message

  def url
    root_url
  end

  notification_methods do
    def message
      "hello #{recipient.email}"
    end

    def url
      root_url
    end
  end
end
