require 'twirp'

module TwirpRails
  module ErrorHandling
    class Base
      ExceptionHandler = Struct.new(:exception, :proc) do
        def match?(exception)
          exception.is_a?(self.exception)
        end

        def handle(exception, handler)
          proc.call(exception, handler)
        end

        def process(exception, handler)
          match?(exception) ? handle(exception, handler) : nil
        end
      end

      ErrorHandler = Struct.new(:code, :proc) do
        def match?(error)
          error.code == self.code
        end

        def handle(error, client)
          proc.call(error, client)
        end

        def process(error, client)
          match?(error) ? handle(error, client) : nil
        end
      end

      class << self
        # translate_exception InvalidArgument, :invalid_argument
        #
        # translate_exception StandardError { |exception, service| Twirp::Error.internal_with exception }
        def translate_exception(*exceptions, with: nil, &block)
          raise 'unexpected with and block' if block_given? && with
          raise 'with or block must be defined' unless block_given? || with


          proc = if with
                   raise "invalid twirp code #{with}" unless ::Twirp::ERROR_CODES.include?(with)

                   proc do |exception, _service|
                     ::Twirp::Error.new(with, exception.message).tap { |t| t.cause = exception }
                   end
                 else
                   proc { |exception, service| block.call(exception, service) }
                 end

          exceptions.each do |exception|
            exception_handlers << ExceptionHandler.new(exception, proc)
          end
        end

        # translate_error :invalid_argument, InvalidArgument
        #
        # translate_error :internal_error { |error, client| StandardError.new(error.msg) }
        def translate_error(*codes, with: nil, &block)
          raise 'unexpected with and block' if block_given? && with.nil?
          raise 'with or block must be defined' unless block_given? || !with.nil?
          raise "invalid twirp code(s) #{codes - ::Twirp::ERROR_CODES}" if (codes - ::Twirp::ERROR_CODES).any?

          proc = if with
                   raise 'with should be a exception class' unless with.is_a?(Class)

                   proc { |error, _client| with.new error.msg }
                 else
                   proc { |error, client| block.call(error, client) }
                 end

          codes.each do |code|
            error_handlers << ErrorHandler.new(code, proc)
          end
        end

        def exception_handlers
          @exception_handlers ||= []
        end

        def error_handlers
          @error_handlers ||= []
        end

        def exception_to_twirp(exception, handler)
          result = nil

          exception_handlers.take_while do |exception_handler|
            result = exception_handler.process(exception, handler)

            result.nil?
          end

          result || ::Twirp::Error.internal_with(exception)
        end

        def twirp_to_exception(error, client)
          result = nil

          error_handlers.take_while do |handler|
            result = handler.process(error, client)

            result.nil?
          end

          result || StandardError.new(error.msg)
        end
      end
    end
  end
end

