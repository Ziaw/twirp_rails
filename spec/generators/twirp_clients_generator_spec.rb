require 'spec_helper'
require 'generator_spec'

RSpec.describe Twirp::ClientsGenerator, type: :generator do
  destination File.expand_path('../../tmp/dummy', __dir__)

  before(:all) do
    prepare_destination
    FileUtils.cp_r File.expand_path('../dummy', __dir__), File.expand_path('../../tmp', __dir__)
    FileUtils.rm_r File.expand_path('../../tmp/dummy/lib/twirp_clients', __dir__), force: true
    run_generator
  end

  it 'generates code from all proto files' do
    assert_file 'lib/twirp_clients/client_test_pb.rb'
    assert_file 'lib/twirp_clients/client_test_twirp.rb'

    assert_file 'lib/twirp_clients/pkg/subpkg/test_pb.rb'
    assert_file 'lib/twirp_clients/pkg/subpkg/test_twirp.rb'

    assert_file 'lib/twirp_clients/shared_twirp.rb'
    assert_file 'lib/twirp_clients/shared_pb.rb'
  end
end
