require 'rails_helper'
require 'generator_spec'

RSpec.describe TwirpGenerator, type: :generator do
  destination File.expand_path('../../tmp/dummy', __dir__)
  arguments %w[test]

  before(:all) do
    prepare_destination
    FileUtils.cp_r File.expand_path('../dummy', __dir__), File.expand_path('../../tmp', __dir__)
    run_generator
  end

  it 'detect test_api.proto a correct handler with full package name' do
    assert_file 'app/rpc/pkg/subpkg/test_api_handler.rb', /class Pkg::Subpkg::TestAPIHandler/ do |handler|
      assert_instance_method :get_name, handler
    end
  end
end
