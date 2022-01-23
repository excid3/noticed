require "test_helper"

class CustomDeliveryMethod < Noticed::DeliveryMethods::Base
  class_attribute :deliveries, default: []

  def deliver
    self.class.deliveries << params
  end
end

class JsonWithBasicAuthDeliveryMethod < Noticed::DeliveryMethods::Base
  class_attribute :response, default: nil

  def deliver
    self.class.response = post("http://example.com", basic_auth: {user: "user", pass: "pass"}, json: {data: "test"})
  end
end

class FormNoBasicAuthDeliveryMethod < Noticed::DeliveryMethods::Base
  class_attribute :response, default: nil

  def deliver
    self.class.response = post("http://example.com", form: {data: "test"})
  end
end

class CustomConnectionDeliveryMethod < Noticed::DeliveryMethods::Base
  class_attribute :response, default: nil

  def deliver
    self.class.response = post("http://example.com", json: {data: "test"})
  end

  def build_connection(args)
    Faraday.new do |f|
      f.headers["X-Custom-Header"] = "test"
      f.response :raise_error
    end
  end
end

class CustomDeliveryJsonExample < Noticed::Base
  deliver_by :json_with_auth, class: "JsonWithBasicAuthDeliveryMethod"
end

class CustomDeliveryFormExample < Noticed::Base
  deliver_by :form_no_auth, class: "FormNoBasicAuthDeliveryMethod"
end

class CustomConnectionDeliveryExample < Noticed::Base
  deliver_by :custom_connection, class: "CustomConnectionDeliveryMethod"
end

class CustomDeliveryMethodExample < Noticed::Base
  deliver_by :example, class: "CustomDeliveryMethod"
end

class DeliveryMethodWithOptions < Noticed::DeliveryMethods::Test
  option :foo
end

class DeliveryMethodWithOptionsExample < Noticed::Base
  deliver_by :example, class: "DeliveryMethodWithOptions"
end

class DeliveryMethodWithNilOptionsExample < Noticed::Base
  deliver_by :example, class: "DeliveryMethodWithOptions", foo: nil
end

class Noticed::DeliveryMethods::BaseTest < ActiveSupport::TestCase
  test "can use custom delivery method with params" do
    CustomDeliveryMethodExample.new.deliver(user)
    assert_equal 1, CustomDeliveryMethod.deliveries.count
  end

  test "validates delivery method options" do
    assert_raises Noticed::ValidationError do
      DeliveryMethodWithOptionsExample.new.deliver(user)
    end
  end

  test "nil options are valid" do
    assert_difference "Noticed::DeliveryMethods::Test.delivered.count" do
      DeliveryMethodWithNilOptionsExample.new.deliver(user)
    end
  end

  test "post json with basic auth" do
    stub_request(:post, "http://example.com")
    CustomDeliveryJsonExample.new.deliver(user)
    response = JsonWithBasicAuthDeliveryMethod.response
    assert_equal({data: "test"}.to_json, response.env.request_body)
    assert_equal "application/json", response.env.request_headers["Content-Type"]
    assert_equal "Basic #{Base64.strict_encode64("user:pass").chomp}", response.env.request_headers["Authorization"]
  end

  test "post form no basic auth" do
    stub_request(:post, "http://example.com")
    CustomDeliveryFormExample.new.deliver(user)
    response = FormNoBasicAuthDeliveryMethod.response
    assert_equal "data=test", response.env.request_body
    assert_equal "application/x-www-form-urlencoded", response.env.request_headers["Content-Type"]
    assert_nil response.env.request_headers["Authorization"]
  end

  test "delivery with custom connection" do
    stub_request(:post, "http://example.com").to_return(status: 400)
    assert_raises Faraday::BadRequestError do
      CustomConnectionDeliveryExample.new.deliver(user)
      response = CustomConnectionDeliveryMethod.response
      assert_equal "test", response.env.request_headers["X-Custom-Header"]
    end
  end
end
