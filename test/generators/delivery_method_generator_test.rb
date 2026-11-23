require "test_helper"
require "generators/noticed/delivery_method_generator"

class DeliveryMethodGeneratorTest < Rails::Generators::TestCase
  tests Noticed::Generators::DeliveryMethodGenerator
  destination File.expand_path("../dummy/tmp/generators", __dir__)
  setup :prepare_destination

  test "skips ApplicationDeliveryMethod when the constant is already defined" do
    # The dummy app defines ApplicationDeliveryMethod
    run_generator ["Discord"]

    assert_no_file "app/notifiers/application_delivery_method.rb"
    assert_file "app/notifiers/delivery_methods/discord.rb", /class DeliveryMethods::Discord < ApplicationDeliveryMethod/
  end

  test "generates ApplicationBulkDeliveryMethod when it doesn't exist" do
    run_generator ["Discord", "--bulk"]

    assert_file "app/notifiers/application_bulk_delivery_method.rb", /class ApplicationBulkDeliveryMethod < Noticed::BulkDeliveryMethod/
    assert_file "app/notifiers/bulk_delivery_methods/discord.rb", /class BulkDeliveryMethods::Discord < ApplicationBulkDeliveryMethod/
  end
end
