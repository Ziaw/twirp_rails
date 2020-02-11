require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../config/environment', __dir__)

abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'twirp_rails/rspec/helper'

Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

Rails.application.eager_load!

RSpec.configure do |config|
  config.include RSpec::Rails::RequestExampleGroup, type: :request, file_path: %r{spec/api}
  config.include TwirpRails::RSpec::Helper, type: :rpc, file_path: %r{spec/rpc}
  config.include FactoryBot::Syntax::Methods

  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  WebMock::disable_net_connect!(allow_localhost: true)

  Shoulda::Matchers.configure do |cfg|
    cfg.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
end
