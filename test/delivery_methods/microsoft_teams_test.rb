require "test_helper"

class MicrosoftTeamsTest < ActiveSupport::TestCase
  class MicrosoftTeamsExample < Noticed::Base
    deliver_by :microsoft_teams, debug: true, url: :teams_url, format: :to_teams

    def teams_url
      "https://outlook.office.com/webhooks/00000-00000/IncomingWebhook/00000-00000"
    end

    def to_teams
      {
        title: "This is the title",
        text: "this is the text",
        section: sections,
        potentialAction: actions
      }
    end

    def sections
      [{activityTitle: "Section Title", activityText: "Section Text"}]
    end

    def actions
      [{
        "@type": "OpenUri",
        name: "View on Foo.Com",
        targets: [{os: "default", uri: "https://foo.example.com"}]
      }]
    end
  end

  test "sends a POST to Teams" do
    Noticed::DeliveryMethods::MicrosoftTeams.any_instance.expects(:post)
    MicrosoftTeamsExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    e = assert_raises(::Noticed::ResponseUnsuccessful) {
      MicrosoftTeamsExample.new.deliver(user)
    }

    assert_equal HTTP::Response, e.response.class
  end

  test "deliver returns an http response" do
    Noticed::Base.any_instance.stubs(:teams_url).returns("https://outlook.office.com/webhooks/00000-00000/IncomingWebhook/00000-00000")
    args = {
      notification_class: "Noticed::Base",
      recipient: user,
      options: {url: :teams_url}
    }
    e = assert_raises(Noticed::ResponseUnsuccessful) {
      Noticed::DeliveryMethods::MicrosoftTeams.new.perform(args)
    }

    assert_kind_of HTTP::Response, e.response
  end
end
