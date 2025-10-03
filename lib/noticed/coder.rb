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
      if ActiveJob::Arguments.respond_to?(:serialize_argument, true)
        ActiveJob::Arguments.send(:serialize_argument, data)
      else
        ActiveJob::Arguments.serialize(data)
      end
    end
  end
end
