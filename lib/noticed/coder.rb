require "active_job/arguments"

module Noticed
  class Coder
    def self.load(data)
      return if data.nil?
      ActiveJob::Arguments.send(:deserialize_argument, data)
    rescue ActiveRecord::RecordNotFound => error
      {noticed_error: error.message, original_params: data}
    end

    def self.dump(data)
      return if data.nil?
      if Rails.gem_version >= Gem::Version.new("8.1.0.beta1")
        ActiveJob::Arguments.serialize(data)
      else
        ActiveJob::Arguments.send(:serialize_argument, data)
      end
    end
  end
end
