### Microsoft Teams Delivery Method

Sends a Teams notification via webhook.

`deliver_by :microsoft_teams`

#### Options

* `format: :format_for_teams` - *Optional*

  Use a custom method to define the payload sent to Microsoft Teams. Method should return a Hash.
  Documentation for posting via Webhooks available at: https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook

  ```ruby
  {
    title: "This is the title for the card",
    text: "This is the body text for the card",
    sections: [{activityTitle: "Section Title", activityText: "Section Text"}],
    "potentialAction": [{
      "@type": "OpenUri",
      name: "Button Text",
      targets: [{
        os: "default",
        uri: "https://example.com/foo/action"
      }]
    }]

  }
  ```

* `url: :url_for_teams_channel`: - *Optional*

  Use a custom method to retrieve the MS Teams Webhook URL. Method should return a string.

  Defaults to `Rails.application.credentials.microsoft_teams[:notification_url]`


