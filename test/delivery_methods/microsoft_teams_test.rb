require "test_helper"

class MicrosoftTeamsTest < ActiveSupport::TestCase
  setup do
    stub_request(:post, /outlook.office.com/).to_return(File.new(file_fixture("microsoft_teams.txt")))
  end

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
    MicrosoftTeamsExample.new.deliver(user)
  end

  test "raises an error when http request fails" do
    without_webmock do
      e = assert_raises(::Noticed::ResponseUnsuccessful) {
        MicrosoftTeamsExample.new.deliver(user)
      }

      assert_equal HTTP::Response, e.response.class
    end
  end

  test "deliver returns an http response" do
    args = {
      notification_class: "::MicrosoftTeamsTest::MicrosoftTeamsExample",
      recipient: user,
      options: {url: :teams_url, format: :to_teams}
    }
    response = Noticed::DeliveryMethods::MicrosoftTeams.new.perform(args)

    assert_kind_of HTTP::Response, response
  end
end
