require "test_helper"

class TelegramTest < ActiveSupport::TestCase
  setup do
    @delivery_method = Noticed::DeliveryMethods::Telegram.new
    @bot_token = "7748670358:AAHBuZIV1VqPWCjsjwpTGrjmY0-0DFFlTLU"
    @chat_id = "450462613"
    @test_message = "Test message with <b>HTML</b>, *markdown*, and [links](https://www.youtube.com/watch?v=gAfF0n_SdO4) - https://example.com"
    set_config(
      bot_token: @bot_token,
      chat_id: @chat_id,
      text: @test_message
    )
  end

  test "sends a telegram message with required fields" do
    expected_url = "https://api.telegram.org/bot#{@bot_token}/sendMessage"
    expected_json = {
      chat_id: @chat_id,
      text: @test_message
    }

    stub_request(:post, expected_url)
      .with(
        body: expected_json.to_json,
        headers: {"Content-Type" => "application/json"}
      )
      .to_return(
        status: 200,
        body: {ok: true, result: {message_id: 1}}.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    assert_nothing_raised do
      @delivery_method.deliver
    end
  end

  test "includes optional parse_mode in payload" do
    @delivery_method.config[:parse_mode] = "HTML"
    expected_url = "https://api.telegram.org/bot#{@bot_token}/sendMessage"
    expected_json = {
      chat_id: @chat_id,
      text: @test_message,
      parse_mode: "HTML"
    }

    stub_request(:post, expected_url)
      .with(body: expected_json.to_json)
      .to_return(status: 200, body: {ok: true}.to_json, headers: {"Content-Type" => "application/json"})

    assert_nothing_raised do
      @delivery_method.deliver
    end
  end

  test "includes optional disable_web_page_preview in payload" do
    @delivery_method.config[:disable_web_page_preview] = true
    expected_url = "https://api.telegram.org/bot#{@bot_token}/sendMessage"
    expected_json = {
      chat_id: @chat_id,
      text: @test_message,
      disable_web_page_preview: true
    }

    stub_request(:post, expected_url)
      .with(body: expected_json.to_json)
      .to_return(status: 200, body: {ok: true}.to_json, headers: {"Content-Type" => "application/json"})

    assert_nothing_raised do
      @delivery_method.deliver
    end
  end

  test "includes optional disable_notification in payload" do
    @delivery_method.config[:disable_notification] = true
    expected_url = "https://api.telegram.org/bot#{@bot_token}/sendMessage"
    expected_json = {
      chat_id: @chat_id,
      text: @test_message,
      disable_notification: true
    }

    stub_request(:post, expected_url)
      .with(body: expected_json.to_json)
      .to_return(status: 200, body: {ok: true}.to_json, headers: {"Content-Type" => "application/json"})

    assert_nothing_raised do
      @delivery_method.deliver
    end
  end

  test "merges custom json payload with required fields" do
    @delivery_method.config[:json] = {
      reply_markup: {
        inline_keyboard: [
          [{text: "View", url: "https://example.com"}]
        ]
      }
    }
    expected_url = "https://api.telegram.org/bot#{@bot_token}/sendMessage"
    expected_json = {
      chat_id: @chat_id,
      text: @test_message,
      reply_markup: {
        inline_keyboard: [
          [{text: "View", url: "https://example.com"}]
        ]
      }
    }

    stub_request(:post, expected_url)
      .with(body: expected_json.to_json)
      .to_return(status: 200, body: {ok: true}.to_json, headers: {"Content-Type" => "application/json"})

    assert_nothing_raised do
      @delivery_method.deliver
    end
  end

  test "raises error on failed response" do
    expected_url = "https://api.telegram.org/bot#{@bot_token}/sendMessage"
    stub_request(:post, expected_url)
      .to_return(status: 400, body: {ok: false, description: "Bad Request"}.to_json, headers: {"Content-Type" => "application/json"})

    assert_raises Noticed::ResponseUnsuccessful do
      @delivery_method.deliver
    end
  end

  test "raises error on 200 status with ok: false" do
    expected_url = "https://api.telegram.org/bot#{@bot_token}/sendMessage"
    stub_request(:post, expected_url)
      .to_return(status: 200, body: {ok: false, description: "Bad Request"}.to_json, headers: {"Content-Type" => "application/json"})

    assert_raises Noticed::ResponseUnsuccessful do
      @delivery_method.deliver
    end
  end

  test "doesnt raise error on failed 200 status code request with raise_if_not_ok false" do
    @delivery_method.config[:raise_if_not_ok] = false
    expected_url = "https://api.telegram.org/bot#{@bot_token}/sendMessage"
    stub_request(:post, expected_url)
      .to_return(status: 200, body: {ok: false, description: "Bad Request"}.to_json, headers: {"Content-Type" => "application/json"})

    assert_nothing_raised do
      @delivery_method.deliver
    end
  end

  private

  def set_config(config)
    @delivery_method.instance_variable_set :@config, ActiveSupport::HashWithIndifferentAccess.new(config)
  end
end

