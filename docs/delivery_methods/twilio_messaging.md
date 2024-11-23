# Twilio Messaging Delivery Method

Sends an SMS or Whatsapp message via Twilio Messaging.

```ruby
deliver_by :twilio_messaging do |config|
  config.json = ->{
    {
      From: phone_number,
      To: recipient.phone_number,
      Body: params.fetch(:message)
    }
  }

  config.credentials = {
    phone_number: Rails.application.credentials.dig(:twilio, :phone_number),
    account_sid: Rails.application.credentials.dig(:twilio, :account_sid),
    auth_token: Rails.application.credentials.dig(:twilio, :auth_token)
  }
  # config.credentials = Rails.application.credentials.twilio
  # config.phone = "+1234567890"
  # config.url = "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json"
end
```

## Content Templates

```ruby
deliver_by :twilio_messaging do |config|
  config.json = -> {
    {
       From: "+1234567890",
       To: recipient.phone_number,
       ContentSid: "value", # Template SID
       ContentVariables: {1: recipient.first_name}
    }
  }
end
```

## Error Handling

Twilio provides a full list of error codes that can be handled as needed. See https://www.twilio.com/docs/api/errors

```ruby
deliver_by :twilio_messaging do |config|
  config.error_handler = lambda do |twilio_error_response|
    error_hash = JSON.parse(twilio_error_response.body)
    case error_hash["code"]
    when 21211
      # The 'To' number is not a valid phone number.
      # Write your error handling code
    else
      raise "Unhandled Twilio error: #{error_hash}"
    end
  end
end
```

## Options

* `json` - *Optional*

  Use a custom method to define the payload sent to Twilio. Method should return a Hash.

  Defaults to:

  ```ruby
  {
    Body: params[:message], # From notification.params
    From: Rails.application.credentials.twilio[:phone_number],
    To: recipient.phone_number
  }
  ```

* `credentials` - *Optional*

  Retrieve the credentials for Twilio. Should return a Hash with `:account_sid`, `:auth_token` and `:phone_number` keys.

  Defaults to `Rails.application.credentials.twilio[:account_sid]` and `Rails.application.credentials.twilio[:auth_token]`

* `url` - *Optional*

  Retrieve the Twilio URL. Should return the Twilio API url as a string.

  Defaults to `"https://api.twilio.com/2010-04-01/Accounts/#{twilio_credentials(recipient)[:account_sid]}/Messages.json"`
