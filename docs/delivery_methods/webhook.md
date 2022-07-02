### Webhook Delivery Method

Sends a notification via webhook.

`deliver_by :webhook, url: "https://webhook.site/0090u9-989238u-23898u-1823"`

##### Options

* `format: :format_for_webhook` - *Optional*

  Use a custom method to define the payload sent to webhook URL. Method should return a Hash.

* `url: :url_for_webhook` - **Required**

  Use a custom method to retrieve the Webhook URL. Method should return a String.


