require 'spec_helper'
require 'generator_spec'

RSpec.describe TwirpGenerator, type: :generator do
  destination File.expand_path('../../tmp/dummy', __dir__)
  arguments %w[test]

  before(:all) do
    prepare_destination
    FileUtils.cp_r File.expand_path('../dummy', __dir__), File.expand_path('../../tmp', __dir__)
    FileUtils.rm_r File.expand_path('../../tmp/dummy/lib/twirp', __dir__), force: true
    FileUtils.mkdir_p File.expand_path('../../tmp/dummy/lib/twirp', __dir__)
    run_generator
  end

  it 'creates a correct handler with full package name' do
    assert_file 'app/rpc/pkg/subpkg/test_api_handler.rb', /class Pkg::Subpkg::TestApiHandler/ do |handler|
      assert_instance_method :get_name, handler
    end
  end
end
