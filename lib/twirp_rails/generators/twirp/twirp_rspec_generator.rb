require 'rails/generators'

module Twirp
  class RspecGenerator < Rails::Generators::Base
    desc 'Install twirp rspec helpers into rails_helper.rb'
    def inject_rspec_helper
      in_root do
        unless File.exist?('spec/rails_helper.rb')
          log :inject_rspec, 'spec/rails_helper.rb is not found'
          return
        end

        require_sentinel = %r{require 'rspec/rails'\s*\n}m
        include_sentinel = /RSpec\.configure\s*do\s*\|config\|\s*\n/m

        inject_into_file 'spec/rails_helper.rb',
                         "require 'twirp_rails/rspec/helper'\n",
                         after: require_sentinel, verbose: true, force: false
        inject_into_file 'spec/rails_helper.rb',
                         "  config.include TwirpRails::RSpec::Helper, type: :rpc, file_path: %r{spec/rpc}\n",
                         after: include_sentinel, verbose: true, force: false
      end
    end
  end
end
