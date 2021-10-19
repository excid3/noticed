### Vonage SMS

Sends an SMS notification via Vonage / Nexmo.

`deliver_by :vonage`

##### Options

* `credentials: :get_credentials` - *Optional*

  Use a custom method for retrieving credentials. Method should return a Hash with `:api_key` and `:api_secret` keys.

  Defaults to `Rails.application.credentials.vonage[:api_key]` and `Rails.application.credentials.vonage[:api_secret]`

* `deliver_by :vonage, format: :format_for_vonage` - *Optional*

  Use a custom method to generate the params sent to Vonage. Method should return a Hash. Defaults to:

  ```ruby
  {
    api_key: vonage_credentials[:api_key],
    api_secret: vonage_credentials[:api_secret],
    from: notification.params[:from],
    text: notification.params[:body],
    to: notification.params[:to],
    type: "unicode"
  }
  ```
