require 'spec_helper'
require 'generator_spec'

RSpec.describe TwirpGenerator, type: :generator do
  destination File.expand_path('../../tmp/dummy', __dir__)
  arguments %w(sample)

  before(:all) do
    prepare_destination
    FileUtils.cp_r File.expand_path('../dummy', __dir__), File.expand_path('../../tmp', __dir__)
    FileUtils.rm_r File.expand_path('../../tmp/dummy/lib/twirp', __dir__), force: true
    FileUtils.mkdir_p File.expand_path('../../tmp/dummy/lib/twirp', __dir__)
    run_generator
  end

  it 'creates a handler' do
    assert_file 'app/rpc/sample_handler.rb', /class SampleHandler/ do |handler|
      assert_instance_method :sample, handler
    end
  end

  it 'generates files from all proto files' do
    assert_file 'lib/twirp/sample_twirp.rb' do |sample|
      assert_match /class SampleService/, sample
      assert_match /rpc\ :sample,\ SampleRequest,\ Shared::Status,\ :ruby_method\ =>\ :sample/, sample
    end
    assert_file 'lib/twirp/sample_pb.rb', /add_file\("sample\.proto",\ :syntax\ =>\ :proto3\)/

    assert_file 'lib/twirp/people_twirp.rb', /class PeopleService/
    assert_file 'lib/twirp/people_pb.rb', /add_file\("people\.proto",\ :syntax\ =>\ :proto3\)/

    assert_file 'lib/twirp/shared_twirp.rb', /module Shared/
    assert_file 'lib/twirp/shared_pb.rb', /module Shared\s+Status =/m
  end

  it 'generates rspec file' do
    assert_file 'spec/rpc/sample_handler_spec.rb' do |sample|
      assert_match /describe SampleHandler/, sample
      assert_match /context '#sample' do/, sample
    end
  end

  it 'generate swagger file' do
    assert_file 'public/swagger/sample.swagger.json', /sample/
  end

  it 'generates route' do
    assert_file 'config/routes.rb', /mount_twirp 'sample'/
  end
end
