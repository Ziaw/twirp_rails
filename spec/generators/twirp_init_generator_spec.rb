require 'spec_helper'
require 'generator_spec'

RSpec.describe Twirp::InitGenerator, type: :generator do
  destination File.expand_path('../../tmp/dummy', __dir__)

  before(:all) do
    prepare_destination
    FileUtils.cp_r File.expand_path('../dummy', __dir__), File.expand_path('../../tmp', __dir__)
    FileUtils.rm_r File.expand_path('../../tmp/dummy/lib/twirp', __dir__), force: true
    FileUtils.mkdir_p File.expand_path('../../tmp/dummy/lib/twirp', __dir__)
    run_generator
  end

  it 'creates a initializer' do
    assert_file 'config/initializers/twirp_rails.rb', /TwirpRails.configure do/
  end
end
