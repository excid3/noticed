# frozen_string_literal: true

require "test_helper"

class Noticed::Deliverable::DeliverByTest < ActiveSupport::TestCase
  class TestDelivery < Noticed::Deliverable::DeliverBy; end

  test "#perform? returns true when no conditionals are configured" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    assert_equal TestDelivery.new(:test, config).perform?({}), true
  end

  test "#perform? returns true when :if is true" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    config.if = -> { true }
    assert_equal TestDelivery.new(:test, config).perform?({}), true
  end

  test "#perform? returns false when :if is false" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    config.if = -> { false }
    assert_equal TestDelivery.new(:test, config).perform?({}), false
  end

  test "#perform? returns false when :unless is true" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    config.unless = -> { true }
    assert_equal TestDelivery.new(:test, config).perform?({}), false
  end

  test "#perform? returns true when :unless is false" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    config.unless = -> { false }
    assert_equal TestDelivery.new(:test, config).perform?({}), true
  end

  test "#perform? takes context into account" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    config.if = -> { key?(:test_value) }
    assert_equal TestDelivery.new(:test, config).perform?({test_value: true}), true
    assert_equal TestDelivery.new(:test, config).perform?({other_value: true}), false
  end
end
