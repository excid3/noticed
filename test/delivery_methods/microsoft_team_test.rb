require "test_helper"

class MicrosoftTeamTest < ActiveSupport::TestCase
  class MicrosoftTeamExample < Noticed::Base
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
    Noticed::DeliveryMethods::MicrosoftTeam.any_instance.expects(:post)
    MicrosoftTeamExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    e = assert_raises(::Noticed::ResponseUnsuccessful) {
      MicrosoftTeamExample.new.deliver(user)
    }

    assert_equal HTTP::Response, e.response.class
  end
end
