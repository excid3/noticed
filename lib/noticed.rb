require "noticed/version"
require "noticed/engine"

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.ignore("#{__dir__}/generators")
loader.do_not_eager_load("#{__dir__}/noticed/bulk_delivery_methods")
loader.do_not_eager_load("#{__dir__}/noticed/delivery_methods")
loader.do_not_eager_load("#{__dir__}/noticed/notification_channel.rb")
loader.setup

module Noticed
  include ActiveSupport::Deprecation::DeprecatedConstantAccessor

  def self.deprecator # :nodoc:
    @deprecator ||= ActiveSupport::Deprecation.new("3.0", "Noticed")
  end

  deprecate_constant :Base, "Noticed::Event", deprecator: deprecator

  module DeliveryMethods
    include ActiveSupport::Deprecation::DeprecatedConstantAccessor

    deprecate_constant :Base, "Noticed::DeliveryMethod", deprecator: Noticed.deprecator
  end

  mattr_accessor :parent_class
  @@parent_class = "Noticed::ApplicationJob"

  class ValidationError < StandardError; end

  class ResponseUnsuccessful < StandardError
    attr_reader :response

    def initialize(response, url, args)
      @response = response
      @url = url
      @args = args

      super("POST request to #{url} returned #{response.code} response:\n#{response.body.inspect}")
    end
  end
end
