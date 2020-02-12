# frozen_string_literal: true

require 'twirp_rails/version'
require 'twirp_rails/engine'
require 'twirp_rails/generators/twirp/twirp_generator'
require 'twirp_rails/generators/twirp/twirp_rspec_generator'
require 'twirp_rails/active_record_extension'

module TwirpRails
  class Error < StandardError; end
end
