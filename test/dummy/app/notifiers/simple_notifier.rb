class SimpleNotifier < Noticed::Event
  deliver_by :test
  required_params :message

  def url
    root_url(host: "example.org")
  end

  notification_methods do
    def message
      "hey its me"
    end
  end
end
