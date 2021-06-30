# frozen_string_literal: true

# First add Rails 6.0 ActiveJob Serializers support, and then the
# DurationSerializer and SymbolSerializer.
module ActiveJob
  module Arguments
    # :nodoc:
    OBJECT_SERIALIZER_KEY = "_aj_serialized"

    def serialize_argument(argument)
      case argument
      when *TYPE_WHITELIST
        argument
      when GlobalID::Identification
        convert_to_global_id_hash(argument)
      when Array
        argument.map { |arg| serialize_argument(arg) }
      when ActiveSupport::HashWithIndifferentAccess
        serialize_indifferent_hash(argument)
      when Hash
        symbol_keys = argument.each_key.grep(Symbol).map(&:to_s)
        result = serialize_hash(argument)
        result[SYMBOL_KEYS_KEY] = symbol_keys
        result
      when ->(arg) { arg.respond_to?(:permitted?) }
        serialize_indifferent_hash(argument.to_h)
      else # Add Rails 6 support for Serializers
        Serializers.serialize(argument)
      end
    end

    def deserialize_argument(argument)
      case argument
      when String
        argument
      when *TYPE_WHITELIST
        argument
      when Array
        argument.map { |arg| deserialize_argument(arg) }
      when Hash
        if serialized_global_id?(argument)
          deserialize_global_id argument
        elsif custom_serialized?(argument)
          Serializers.deserialize(argument)
        else
          deserialize_hash(argument)
        end
      else
        raise ArgumentError, "Can only deserialize primitive arguments: #{argument.inspect}"
      end
    end

    def custom_serialized?(hash)
      hash.key?(OBJECT_SERIALIZER_KEY)
    end
  end

  # The <tt>ActiveJob::Serializers</tt> module is used to store a list of known serializers
  # and to add new ones. It also has helpers to serialize/deserialize objects.
  module Serializers # :nodoc:
    # Base class for serializing and deserializing custom objects.
    #
    # Example:
    #
    #   class MoneySerializer < ActiveJob::Serializers::ObjectSerializer
    #     def serialize(money)
    #       super("amount" => money.amount, "currency" => money.currency)
    #     end
    #
    #     def deserialize(hash)
    #       Money.new(hash["amount"], hash["currency"])
    #     end
    #
    #     private
    #
    #       def klass
    #         Money
    #       end
    #   end
    class ObjectSerializer
      include Singleton

      class << self
        delegate :serialize?, :serialize, :deserialize, to: :instance
      end

      # Determines if an argument should be serialized by a serializer.
      def serialize?(argument)
        argument.is_a?(klass)
      end

      # Serializes an argument to a JSON primitive type.
      def serialize(hash)
        {Arguments::OBJECT_SERIALIZER_KEY => self.class.name}.merge!(hash)
      end

      # Deserializes an argument from a JSON primitive type.
      def deserialize(_argument)
        raise NotImplementedError
      end

      private

      # The class of the object that will be serialized.
      def klass
        raise NotImplementedError
      end
    end

    class DurationSerializer < ObjectSerializer # :nodoc:
      def serialize(duration)
        super("value" => duration.value, "parts" => Arguments.serialize(duration.parts.each_with_object({}) { |v, s| s[v.first.to_s] = v.last }))
      end

      def deserialize(hash)
        value = hash["value"]
        parts = Arguments.deserialize(hash["parts"])

        klass.new(value, parts)
      end

      private

      def klass
        ActiveSupport::Duration
      end
    end

    class SymbolSerializer < ObjectSerializer # :nodoc:
      def serialize(argument)
        super("value" => argument.to_s)
      end

      def deserialize(argument)
        argument["value"].to_sym
      end

      private

      def klass
        Symbol
      end
    end

    # -----------------------------

    mattr_accessor :_additional_serializers
    self._additional_serializers = Set.new

    class << self
      # Returns serialized representative of the passed object.
      # Will look up through all known serializers.
      # Raises <tt>ActiveJob::SerializationError</tt> if it can't find a proper serializer.
      def serialize(argument)
        serializer = serializers.detect { |s| s.serialize?(argument) }
        raise SerializationError.new("Unsupported argument type: #{argument.class.name}") unless serializer
        serializer.serialize(argument)
      end

      # Returns deserialized object.
      # Will look up through all known serializers.
      # If no serializer found will raise <tt>ArgumentError</tt>.
      def deserialize(argument)
        serializer_name = argument[Arguments::OBJECT_SERIALIZER_KEY]
        raise ArgumentError, "Serializer name is not present in the argument: #{argument.inspect}" unless serializer_name

        serializer = serializer_name.safe_constantize
        raise ArgumentError, "Serializer #{serializer_name} is not known" unless serializer

        serializer.deserialize(argument)
      end

      # Returns list of known serializers.
      def serializers
        self._additional_serializers # standard:disable Style/RedundantSelf
      end

      # Adds new serializers to a list of known serializers.
      def add_serializers(*new_serializers)
        self._additional_serializers += new_serializers.flatten
      end
    end

    add_serializers DurationSerializer,
      SymbolSerializer
    # The full set of 6 serializers that Rails 6.0 normally adds here -- feel free to include any others if you wish:
    # SymbolSerializer,
    # DurationSerializer, # (The one that we've added above in order to support testing)
    # DateTimeSerializer,
    # DateSerializer,
    # TimeWithZoneSerializer,
    # TimeSerializer
  end

  # Is the updated version of perform_enqueued_jobs from Rails 6.0 missing from ActionJob's TestHelper?
  unless TestHelper.private_instance_methods.include?(:flush_enqueued_jobs)
    module TestHelper
      def perform_enqueued_jobs(only: nil, except: nil, queue: nil)
        return flush_enqueued_jobs(only: only, except: except, queue: queue) unless block_given?

        super
      end

      private

      def jobs_with(jobs, only: nil, except: nil, queue: nil)
        validate_option(only: only, except: except)

        jobs.count do |job|
          job_class = job.fetch(:job)

          if only
            next false unless filter_as_proc(only).call(job)
          elsif except
            next false if filter_as_proc(except).call(job)
          end

          if queue
            next false unless queue.to_s == job.fetch(:queue, job_class.queue_name)
          end

          yield job if block_given?

          true
        end
      end

      def enqueued_jobs_with(only: nil, except: nil, queue: nil, &block)
        jobs_with(enqueued_jobs, only: only, except: except, queue: queue, &block)
      end

      def flush_enqueued_jobs(only: nil, except: nil, queue: nil)
        enqueued_jobs_with(only: only, except: except, queue: queue) do |payload|
          instantiate_job(payload).perform_now
          queue_adapter.performed_jobs << payload
        end
      end
    end
  end
end
