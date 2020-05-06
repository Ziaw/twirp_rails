# frozen_string_literal: true

require 'twirp_rails/version'
require 'twirp_rails/engine'
require 'twirp_rails/generators/generators'
require 'twirp_rails/active_record_extension'
require 'twirp_rails/log_subscriber'
require 'twirp_rails/error_handling/error_handling'

module TwirpRails
  class Error < StandardError; end

  class Configuration
    def self.config_param(symbol, default_value = nil, &block)
      raise 'wrong args' if !default_value.nil? && block_given?

      if block_given?
        class_variable_set("@@#{symbol}_default", block)
        class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          def #{symbol}_default
            instance_eval &@@#{symbol}_default
          end
        RUBY
      else
        class_variable_set("@@#{symbol}_default", default_value)
        class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          def #{symbol}_default
            @@#{symbol}_default
          end
        RUBY
      end

      class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def #{symbol}
          @#{symbol} ||= #{symbol}_default
        end
      RUBY

      class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def #{symbol}?
          #{symbol}
        end

        def #{symbol}=(value)
          @#{symbol} = value
        end
      RUBY
    end

    config_param :services_proto_path, 'rpc'

    config_param :clients_proto_path, 'rpc_clients'

    config_param :services_twirp_code_path, 'lib/twirp'

    config_param :clients_twirp_code_path, 'lib/twirp_clients'

    config_param :swagger_output_path, 'public/swagger'

    config_param :log_twirp_calls, true

    config_param :purge_old_twirp_code, true

    config_param :add_api_acronym, true

    config_param :twirp_exception_translator_class, nil
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration if block_given?
    setup
  end

  def self.setup
    if configuration.log_twirp_calls
      if configuration.log_twirp_calls.is_a?(Proc)
        log_twirp_calls!(&configuration.log_twirp_calls)
      else
        log_twirp_calls!
      end
    end
  end

  def self.log_twirp_calls!(&log_writer)
    TwirpRails::LoggingAdapter.install

    TwirpRails::LogSubscriber.log_writer = log_writer if block_given?
    TwirpRails::LogSubscriber.attach_to(:twirp)
  end

  def self.handle_dev_error(msg, &_)
    if Rails.env.development? && !ENV['TWIRP_RAILS_RAISE']
      begin
        yield
      rescue StandardError => e
        warn("#{msg} #{e.message}")
        warn('twirp_rails error raised but control flow will resume for development environment. Define env TWIRP_RAILS_RAISE to raise error.')
      end
    else
      yield
    end
  end

  # Convert google.protobuf.Timestamp or Google::Protobuf::Timestampp hash
  # to [Time]
  # @param [Hash|Google::Protobuf::Timestamp] proto_timestamp
  def self.timestamp_to_time(proto_timestamp)
    return nil unless proto_timestamp

    proto_timestamp = proto_timestamp.to_h unless proto_timestamp.is_a?(Hash)

    seconds = proto_timestamp[:seconds]
    raise "invalid timestamp #{proto_timestamp.inspect}" unless seconds

    nanos = proto_timestamp[:nanos]

    seconds += nanos * 1e-9 unless nanos.nil? || nanos.zero?

    Time.zone.at seconds
  end

  def self.client(klass, url)
    client = klass.new(url)

    TwirpRails::ErrorHandling.wrap_client(client)
  end
end
