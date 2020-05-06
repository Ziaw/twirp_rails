module TwirpRails
  class ErrorHandlingFactory
    class HandlerProxy
      attr_reader :handler, :translator_class

      def initialize(handler, translator_class)
        @handler = handler
        @translator_class = translator_class
      end

      # rubocop:disable Style/MethodMissingSuper
      def method_missing(method, *args)
        handler.public_send method, *args
      rescue => e
        translator_class.exception_to_twirp(e, handler)
      end
      # rubocop:enable Style/MethodMissingSuper

      def respond_to_missing?(method)
        handler.respond_to?(method)
      end
    end

    class ClientProxy
      attr_reader :client, :translator_class

      def initialize(client, translator_class)
        @client = client
        @translator_class = translator_class
      end

      def raise_on_error(twirp_result)
        if twirp_result.error
          exception = translator_class.twirp_to_exception(twirp_result.error)
          raise exception
        else
          twirp_result
        end
      end

      # rubocop:disable Style/MethodMissingSuper
      def method_missing(method, *args)
        if method =~ /!$/
          # when we call a bang version of client method - raise exception translated from error
          method = method[0..-2]
          raise_on_error client.public_send(method, args)
        else
          client.public_send method, args
        end
      end
      # rubocop:enable Style/MethodMissingSuper

      def respond_to_missing?(method)
        handler.respond_to?(method)
      end
    end

    class << self
      attr_reader :translator_class

      def wrap_handler(handler)
        enable_handling? ? HandlerProxy.new(handler, translator_class) : handler
      end

      def wrap_client(client)
        enable_handling? ? ClientProxy.new(client, translator_class) : client
      end

      def enable_handling?
        if @enable_handling.nil?
          if (@translator_class = TwirpRails.configuration.twirp_exception_translator_class)
            @translator_class = @translator_class.constantize unless @translator_class.is_a?(Class)
            @enable_handling = true
          else
            @enable_handling = false
          end
        end
        @enable_handling
      end
    end
  end
end
