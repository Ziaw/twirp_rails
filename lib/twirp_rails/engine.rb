require 'rails/engine'
require 'twirp_rails/routes'
require 'twirp_rails/twirp'

module TwirpRails
  module Routes
    class Engine < ::Rails::Engine
      initializer 'twirp_rails.routes' do
        TwirpRails::Routes::Helper.install
      end

      initializer 'twirp_rails.require_generated_files' do
        TwirpRails::Twirp.auto_require_twirp_files
      end
    end
  end
end
