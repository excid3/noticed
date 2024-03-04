# frozen_string_literal: true

require "test_helper"

class Noticed::Deliverable::DeliverByTest < ActiveSupport::TestCase
  class TestDelivery < Noticed::Deliverable::DeliverBy; end

  test "#perform? returns true when :skip_delivery_if is missing" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    assert_equal true, TestDelivery.new(:test, config).perform?({})
  end

  test "#perform? returns false when :skip_delivery_if is true" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    config.skip_delivery_if = -> { true }
    assert_equal false, TestDelivery.new(:test, config).perform?({})
  end

  test "#perform? returns true when :skip_delivery_if is false" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    config.skip_delivery_if = -> { false }
    assert_equal true, TestDelivery.new(:test, config).perform?({})
  end

  test "#perform? takes context into account" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    config.skip_delivery_if = -> { key?(:test_value) }
    assert_equal false, TestDelivery.new(:test, config).perform?({test_value: true})
    assert_equal true, TestDelivery.new(:test, config).perform?({other_value: true})
  end
end
