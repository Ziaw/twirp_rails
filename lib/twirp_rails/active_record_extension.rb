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
      fields = fields_or_class
      result = attributes

      if fields.empty? && self.class.twirp_message_class
        fields = [self.class.twirp_message_class]
      end

      if fields.one? && fields.first.is_a?(Class)
        message_class = fields.first

        unless message_class.respond_to?(:descriptor)
          raise "Class #{message_class} must me a protobuf message class"
        end

        # TODO performance optimization needed
        fields = message_class.descriptor.map &:name

        result = result.slice(*fields)
      elsif fields.any?
        result = result.slice(*fields)
      end

      result
    end
  end
end

if defined? ActiveRecord::Base
  ActiveRecord::Base.include TwirpRails::ActiveRecordExtension
end
