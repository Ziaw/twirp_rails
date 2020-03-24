require 'rails/generators'

module Twirp
  class InitGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    desc 'This generator creates an initializer file at config/initializers'
    def create_initializer_file
      copy_file 'twirp_rails.rb', 'config/initializers/twirp_rails.rb'
    end
  end
end
