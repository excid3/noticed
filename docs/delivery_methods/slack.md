### Slack Delivery Method

Sends a Slack notification via webhook or API call.

`deliver_by :slack`

##### Options

* `format: :format_for_slack` - *Optional*

  Use a custom method to define the payload sent to Slack. Method should return a Hash.

* `url: :url_for_slack` - *Optional*

  Use a custom method to retrieve the Slack Webhook/API method URL. Method should return a String.

  Defaults to `Rails.application.credentials.slack[:notification_url]`

* `headers: :headers_for_slack` - *Optional*

  Use a custom method to define the headers sent to Slack API. Method should return a Hash. Useful for API calls, where it is necessary to send an authorization token.
