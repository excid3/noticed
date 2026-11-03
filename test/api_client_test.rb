require "test_helper"

class ApiClientTest < ActiveSupport::TestCase
  include Noticed::ApiClient

  test "filters the token of a Discord webhook URL" do
    assert_equal "https://discord.com/api/webhooks/1234567890/[FILTERED]",
      filtered_url("https://discord.com/api/webhooks/1234567890/aBcDeF-gHiJkL_mNoPqRsTuVwXyZ")
  end

  test "filters the token of a Discord webhook URL with a compatibility suffix and query" do
    assert_equal "https://discord.com/api/v10/webhooks/1234567890/[FILTERED]/slack?wait=true&thread_id=42",
      filtered_url("https://discord.com/api/v10/webhooks/1234567890/aBcDeF-gHiJkL/slack?wait=true&thread_id=42")
  end

  test "filters the token of a Slack incoming webhook URL" do
    assert_equal "https://hooks.slack.com/services/T00000000/B00000000/[FILTERED]",
      filtered_url("https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX")
    assert_equal "https://hooks.slack.com/T00000000/B00000000/[FILTERED]",
      filtered_url("https://hooks.slack.com/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX")
  end

  test "leaves the Slack API URL alone" do
    assert_equal Noticed::SlackDelivery::DEFAULT_URL, filtered_url(Noticed::SlackDelivery::DEFAULT_URL)
  end

  test "filters the ids of a Microsoft Teams incoming webhook URL" do
    url = "https://contoso.webhook.office.com/webhookb2/7aa49aa6-7840-443d-806c-08ebe8f59966@c662313f-14fc-43a2-9a7a-d2e27f4f3478/IncomingWebhook/8592f62b50cf41b9b93ba0c0a00a0b88/eff4cd58-1bb8-4899-94de-795f656b4a18/V2/0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0"
    assert_equal "https://contoso.webhook.office.com/webhookb2/7aa49aa6-7840-443d-806c-08ebe8f59966@c662313f-14fc-43a2-9a7a-d2e27f4f3478/IncomingWebhook/[FILTERED]",
      filtered_url(url)
  end

  test "filters the signature of a Microsoft Teams Workflows URL" do
    url = "https://prod-03.westus.logic.azure.com:443/workflows/d4690301f3b340de9330256bb2e83974/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=JXbHjs3qzLPDyk-IM_VzsN-WL_mNql3v_uWbBbKgtVk"
    assert_equal "https://prod-03.westus.logic.azure.com:443/workflows/d4690301f3b340de9330256bb2e83974/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=[FILTERED]",
      filtered_url(url)
  end

  test "filters query parameters using the application's filter_parameters" do
    assert_equal "https://example.org/hooks/orders?token=[FILTERED]&format=json&flag",
      filtered_url("https://example.org/hooks/orders?token=abc123&format=json&flag")
  end

  test "leaves other URLs alone" do
    url = "https://fcm.googleapis.com/v1/projects/my-project/messages:send"
    assert_equal url, filtered_url(url)
    assert_equal "http://localhost:3000/hooks", filtered_url(URI("http://localhost:3000/hooks"))
  end
end
