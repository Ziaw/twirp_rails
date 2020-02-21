# frozen_string_literal: true
require 'twirp_rails/routes'

module TwirpRails
  module RavenAdapter # :nodoc:
    def self.install
      return unless defined?(::Raven)

      TwirpRails::Routes::Helper.on_create_service do |service|
        RavenAdapter.attach service
      end
    end

    def self.attach(service)
      service.exception_raised do |e, _env|
        ::Raven.capture_exception e
      end
    end
  end
end
