# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.4.4 - 2020-05-05

### Added

- ability to translate twirp errors to exceptions and vise versa.

## 0.4.3 - 2020-04-14

### Fixed

- autorequire all ruby files from `lib/twirp_clients` folder.

## 0.4.2 - 2020-04-01

### Added

- `to_twirp` extension use model method unless attribute found 

## 0.4.1 - 2020-03-30

### Added

- smart service detection - you can use `rails g twirp svc` if you `Svc` or 
`SvcAPI` service described at `company/service/subservice/version/etc/svc_api.proto`
- Add `# :nocov:` comment to generated modules to avoid decrease coverage
- Improve generator console output and error handling
- `add_api_acronym` configuration option

### Fixed

- `protoc` path was cached on start and didn't reload with spring

## 0.4.0 - 2020-03-24

### Breaking changes

- Client and server proto directory splits from `app/protos` to `rpc` and `rpc/clients` (configurable)
 
### Added

- Added gem configuration and generator to create initial configuration file `rails g twirp:init` (comments inside).
- Proto source dirs and rb destination dirs now configurable.
- Added separate generator to run protoc on clients proto files `rails g twirp:clients`.
- Add acronym API to Rails inflector to correct generate `ServiceAPI` handler from `ServiceApi` as protoc twirp plugin.
- In the development environment gem uses warn instead of raise errors on incorrect generated code or invalid service routes.  

### Fixed

- Fixed incorrect indent in generated modules.

## 0.3.2 - 2020-03-12

### Added
- Correct code generation for proto files with packages.

## 0.3.1 - 2020-03-10

### Fix
- Fix default log subscriber to use string keys to avoid SemanticLogger use :exception as parameter

## 0.3.0 - 2020-02-28

### Added
- Ability to detailed log twirp calls. Add `TwirpRails.log_twirp_calls!` to the initializer. 

### Breaking changes
- Services not been instrumented via `ActiveSupport::Notifications` unless `TwirpRails.log_twirp_calls!` used.

## 0.2.0 - 2020-02-21

### Breaking changes
- `mount_twirp` now (by default) mounts to path /twirp/Service instead of /Service. If you want to use old 
behavior add `scope: nil` argument.

### Added
- Services mounted by `mount_twirp` now correctly report errors to `Raven` (if `raven` gem used) and instrument
calls via `ActiveSupport::Notifications`.

### Changed
- initial install rspec helper code moved to the ```twirp:rspec``` generator.

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


