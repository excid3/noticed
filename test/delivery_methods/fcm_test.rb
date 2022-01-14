require "test_helper"

class FcmExample < Noticed::Base
  deliver_by :fcm, credentials: :fcm_credentials, format: :format_notification

  def fcm_credentials
    {project_id: "api-12345"}
  end

  def format_notification(device_token)
    {
      token: device_token,
      notification: {
        title: "Hey Chris",
        body: "Am I worky?"
      }
    }
  end
end

class FakeAuthorizer
  def self.make_creds(options = {})
    new
  end

  def fetch_access_token!
    {"access_token" => "access-token-12341234"}
  end
end

class FcmTest < ActiveSupport::TestCase
  test "when credentials option is a hash, it returns the hash" do
    credentials_hash = {foo: "bar"}
    assert_equal credentials_hash, Noticed::DeliveryMethods::Fcm.new.assign_args(notification_class: "FcmExample", options: {credentials: credentials_hash}).credentials
  end

  test "when credentials option is a Pathname object, it returns the file contents" do
    credentials_hash = {project_id: "api-12345"}
    assert_equal credentials_hash, Noticed::DeliveryMethods::Fcm.new.assign_args(notification_class: "FcmExample", options: {credentials: Rails.root.join("config/credentials/fcm.json")}).credentials
  end

  test "when credentials option is a string, it returns the file contents" do
    credentials_hash = {project_id: "api-12345"}
    assert_equal credentials_hash, Noticed::DeliveryMethods::Fcm.new.assign_args(notification_class: "FcmExample", options: {credentials: "config/credentials/fcm.json"}).credentials
  end

  test "when credentials option is a symbol, it returns the return value of the method" do
    credentials_hash = {project_id: "api-12345"}
    assert_equal credentials_hash, Noticed::DeliveryMethods::Fcm.new.assign_args(notification_class: "FcmExample", options: {credentials: :fcm_credentials}).credentials
  end

  test "project_id returns the project id value from the credentials" do
    assert_equal "api-12345", Noticed::DeliveryMethods::Fcm.new.assign_args(notification_class: "FcmExample", options: {credentials: :fcm_credentials}).project_id
  end

  test "access token returns a string" do
    assert_equal "access-token-12341234", Noticed::DeliveryMethods::Fcm.new.assign_args(notification_class: "FcmExample", options: {credentials: :fcm_credentials, authorizer: FakeAuthorizer}).access_token
  end

  test "format" do
    fcm_message = Noticed::DeliveryMethods::Fcm.new.assign_args(notification_class: "FcmExample", options: {credentials: :fcm_credentials, format: :format_notification}).format("12345")
    assert_equal "12345", fcm_message.fetch(:token)
  end
end
