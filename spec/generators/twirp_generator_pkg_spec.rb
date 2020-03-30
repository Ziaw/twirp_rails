require 'spec_helper'
require 'generator_spec'

RSpec.describe TwirpGenerator, type: :generator do
  destination File.expand_path('../../tmp/dummy', __dir__)
  arguments %w[pkg/subpkg/people]

  before(:all) do
    prepare_destination
    FileUtils.cp_r File.expand_path('../dummy', __dir__), File.expand_path('../../tmp', __dir__)
    FileUtils.rm_r File.expand_path('../../tmp/dummy/lib/twirp', __dir__), force: true
    FileUtils.mkdir_p File.expand_path('../../tmp/dummy/lib/twirp', __dir__)
    run_generator
  end

  it 'creates a handler with module' do
    assert_file 'app/rpc/pkg/subpkg/people_handler.rb', /class Pkg::Subpkg::PeopleHandler/ do |handler|
      assert_instance_method :get_name, handler
    end
  end

  it 'generates files from all proto files' do
    assert_file 'lib/twirp/pkg/subpkg/people_twirp.rb' do |sample|
      assert_match /class PeopleService/, sample
    end
    assert_file 'lib/twirp/pkg/subpkg/people_pb.rb', %r{add_file\("pkg/subpkg/people\.proto",\ :syntax\ =>\ :proto3\)}

    assert_file 'lib/twirp/people_twirp.rb', /class PeopleService/
    assert_file 'lib/twirp/people_pb.rb', /add_file\("people\.proto",\ :syntax\ =>\ :proto3\)/

    assert_file 'lib/twirp/shared_twirp.rb', /module Shared/
    assert_file 'lib/twirp/shared_pb.rb', /module Shared\s+Status =/m
  end

  it 'generates rspec file' do
    assert_file 'spec/rpc/pkg/subpkg/people_handler_spec.rb' do |sample|
      assert_match /describe Pkg::Subpkg::PeopleHandler/, sample
      assert_match /context '#get_name' do/, sample
    end
  end

  it 'generate module file' do
    assert_file 'app/rpc/pkg.rb', /module Pkg/

    assert_file 'app/rpc/pkg/subpkg.rb' do |mod|
      assert_match /# :nocov:/, mod
      assert_match /module Pkg/ , mod
      assert_match /module Subpkg/, mod
    end
  end

  it 'generate swagger file' do
    assert_file 'public/swagger/pkg/subpkg/people.swagger.json', /people/
  end

  it 'generates route' do
    assert_file 'config/routes.rb', %r{mount_twirp 'pkg/subpkg/people'}
  end
end
