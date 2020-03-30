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
        TwirpRails.handle_dev_error 'Require services twirp files' do
          path = Pathname.new(TwirpRails.configuration.services_twirp_code_path)
          path = Rails.root.join(path) if path.relative?
          TwirpRails::Twirp.auto_require_twirp_files(path.to_s)
        end
        TwirpRails.handle_dev_error 'Require clients twirp files' do
          path = Pathname.new(TwirpRails.configuration.clients_twirp_code_path)
          path = Rails.root.join(path) if path.relative?
          TwirpRails::Twirp.auto_require_twirp_files(path.to_s)
        end
      end

      initializer 'twirp_rails.add_api_acronym' do
        if TwirpRails.configuration.add_api_acronym do
          ActiveSupport::Inflector.inflections(:en) do |inflect|
            inflect.acronym 'API'
          end
        end
      end
    end
  end
end
