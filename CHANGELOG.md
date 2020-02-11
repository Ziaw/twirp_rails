# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.7 - 2020-02-11

### Changed
- initial inject required rspec helper required code moved to the ```twirp:rspec``` generator.

## 0.1.6 - 2020-02-11

### Added
- ```rails g twirp service``` generates swagger file at public/swagger, options to skip it or set output path 
- ```rails g twirp service``` generates handler rspec test

## 0.1.5 - 2020-02-04

### Added
- rspec ```rpc``` helper try to camelize tested method name if it not exists 

## 0.1.4 - 2020-02-03

### Added
- ```to_twirp``` and ```twirp_message``` methods to easy convert active record models to protobuf DTOs
- rspec helper to test twirp handlers with ```rpc``` helper
```ruby
config.include TwirpRails::RSpec::Helper, type: :rpc, file_path: %r{spec/rpc}
# ...

describe TeamsHandler do
  let!(:team) { create :team }

  context '#get' do
    rpc { [:get, id: team.id] }

    it { should match(team: team.to_twirp.symbolize_keys) }
  end
end
``` 

## 0.1.3 - 2020-01-28

### Added
- convert package.message type to Package::Message

### Fixed
- twirp_ruby missing module workaround https://github.com/twitchtv/twirp-ruby/issues/48

## 0.1.2 - 2020-01-27

### Fixed
- fix generator description bug not catched by tests

## 0.1.1 - 2020-01-27

### Added
- import directive support
- generator always renews all generated _twirp and _pb files from all protos to support import directive
- lib/twirp added to $LOAD_PATH

## 0.1.0 - 2020-01-24

### Added
- mount_twirp route helper
- rails g twirp generator


