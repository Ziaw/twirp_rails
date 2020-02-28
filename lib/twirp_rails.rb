# frozen_string_literal: true

require 'twirp_rails/version'
require 'twirp_rails/engine'
require 'twirp_rails/generators/twirp/twirp_generator'
require 'twirp_rails/generators/twirp/twirp_rspec_generator'
require 'twirp_rails/active_record_extension'
require 'twirp_rails/log_subscriber'

module TwirpRails
  class Error < StandardError; end

  def self.log_twirp_calls!(&log_writer)
    TwirpRails::LoggingAdapter.install

    TwirpRails::LogSubscriber.log_writer = log_writer if block_given?
    TwirpRails::LogSubscriber.attach_to(:twirp)
  end
end
