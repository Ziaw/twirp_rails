require 'rails_helper'
require 'generator_spec'

RSpec.describe Twirp::RspecGenerator, type: :generator do
  destination File.expand_path('../../tmp/dummy', __dir__)

  before(:all) do
    prepare_destination
    FileUtils.cp_r File.expand_path('../dummy', __dir__), File.expand_path('../../tmp', __dir__)
    run_generator
  end

  it 'generates rspec file' do
    assert_file 'spec/rails_helper.rb' do |sample|
      assert_match %r{\nrequire 'twirp_rails/rspec/helper'\n}m, sample
      assert_match %r{\n  config.include TwirpRails::RSpec::Helper, type: :rpc, file_path: %r{spec/rpc}\n}, sample
    end
  end
end
