# frozen_string_literal: true
require 'twirp_rails/routes'

module TwirpRails
  module LoggingAdapter # :nodoc:
    def self.install
      return unless defined?(ActiveSupport::Notifications)

      TwirpRails::Routes::Helper.on_create_service do |service|
        LoggingAdapter.instrument service
      end
    end

    def self.instrument(service)
      instrumenter = ActiveSupport::Notifications.instrumenter

      service.before do |rack_env, env|
        payload = {
          rack_env: rack_env,
          env: env
        }
        instrumenter.start 'instrumenter.twirp', payload
      end

      service.on_error do |_twerr, _env|
        instrumenter.finish 'instrumenter.twirp', {}
      end

      service.on_success do |_env|
        instrumenter.finish 'instrumenter.twirp', {}
      end

      service.exception_raised do |e, env|
        env[:exception] = {
          class: e.class,
          message: e.message,
          backtrace: e.backtrace.join("\n")
        }
      end
    end
  end
end
