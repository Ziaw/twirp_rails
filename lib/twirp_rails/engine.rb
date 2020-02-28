require 'rails/engine'
require 'twirp_rails/routes'
require 'twirp_rails/twirp'
require 'twirp_rails/logging_adapter'
require 'twirp_rails/raven_adapter'

module TwirpRails
  module Routes
    class Engine < ::Rails::Engine
      initializer 'twirp_rails.routes' do
        TwirpRails::Routes::Helper.install
      end

      initializer 'twirp_rails.raven' do
        TwirpRails::RavenAdapter.install
      end

      initializer 'twirp_rails.require_generated_files' do
        TwirpRails::Twirp.auto_require_twirp_files
      end
    end
  end
end
