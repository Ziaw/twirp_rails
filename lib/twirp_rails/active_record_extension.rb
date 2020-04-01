module TwirpRails
  module ActiveRecordExtension
    extend ActiveSupport::Concern

    class_methods do
      # Using to set twirp class used by to_twirp method
      # @example
      # twirp_message TwirpModel
      def twirp_message(message_class)
        @twirp_message = message_class
      end

      def twirp_message_class
        @twirp_message = @twirp_message.constantize if @twirp_message.is_a?(String)

        @twirp_message
      end

      def to_twirp(*args)
        all.map { |entity| entity.to_twirp(*args) }
      end
    end

    # Converts to twirp hash,
    # @return [Hash] of attributes
    # used by relation method to_twirp
    # @param [Array|Class] fields_or_class - array of converted fields or message class to
    def to_twirp(*fields_or_class)
      if fields_or_class.empty? && self.class.twirp_message_class
        to_twirp_as_class(self.class.twirp_message_class)
      elsif fields_or_class.one? && fields_or_class.first.is_a?(Class)
        to_twirp_as_class(fields_or_class.first)
      elsif fields_or_class.any?
        to_twirp_as_fields(fields_or_class)
      else
        attributes
      end
    end

    private

    def to_twirp_as_class(klass)
      unless klass.respond_to?(:descriptor)
        raise "Class #{klass} must be a protobuf message class"
      end

      # TODO performance optimization needed
      to_twirp_as_fields(klass.descriptor.map &:name)
    end

    def to_twirp_as_fields(fields)
      fields.each_with_object({}) do |field, h|
        h[field] = attributes.fetch(field) { public_send(field) }
      end
    end
  end
end

if defined? ActiveRecord::Base
  ActiveRecord::Base.include TwirpRails::ActiveRecordExtension
end
