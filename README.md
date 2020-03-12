# TwirpRails

[![Gem Version](https://badge.fury.io/rb/twirp_rails.svg)](https://badge.fury.io/rb/twirp_rails)

TwirpRails helps to use [twirp-ruby gem](https://github.com/twitchtv/twirp-ruby) with rails.

 * twirp code generation from ```.proto``` file
 * handler, rspec and swagger code generation from ```.proto``` file
 * `mount_twirp` route helper to mount handlers
 * `rpc` helper to dry your handlers specs
 * ability to log twirp calls by Rails logger

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'twirp_rails'
```

See the [twirp-ruby code generation documentation](https://github.com/twitchtv/twirp-ruby/wiki/Code-Generation) 
to install required protoc and twirp-ruby plugin.

## Usage

### Generator

Create a proto file ```app/protos/people.proto```:
```proto
syntax = "proto3";

service People {
    rpc getName(GetNameRequest) returns (GetNameResponse);
}

message GetNameRequest {
    string uid = 1;
}

message GetNameResponse {
    string name = 1;
}
```

and run

```sh
rails g twirp people
rails g twirp:rspec # run only once, if you want to use rspec rpc helper
```

This command will add the route and generate ```lib/twirp/people_pb.rb```, ```lib/twirp/people_twirp.rb```,  
```public/swagger/people.swagger.json```,  ```app/rpc/people_handler.rb``` and ```spec/rpc/people_handler_sprc.rb```.
```ruby
# app/rpc/people_handler.rb

class PeopleHandler

  def get_name(req, _env)
    GetNameResponse.new
  end
end
```

### Call RPC

Modify ```app/rpc/people_handler.rb```:
```ruby
  def get_name(req, _env)
    { name: "Name of #{req.uid}" }
  end
```

Run rails server
```sh
rails s
```

And check it from rails console.
```ruby
PeopleClient.new('http://localhost:3000/twirp').get_name(uid: 'starship').data.name
=> "Name of starship"
```

### Test your service with rspec

If you use RSpec, twirp generator creates handler spec file with all service methods test templates. 

```ruby
describe TeamsHandler do
  context '#get' do
    let(:team) { create(:team) } 
    rpc { [:get, id: team.id] }

    it { should match(team: team.to_twirp) }
  end
end
```

To include required spec helpers add this code to ```rails_helper.rb```
```ruby
require 'twirp_rails/rspec/helper'

RSpec.configure do |config|
  config.include RSpec::Rails::RequestExampleGroup, type: :request, file_path: %r{spec/api}
end 
```

or run ```rails g twirp:rspec``` to do it automatically.

## Log twirp calls

By default, Rails logs only start of POST request. To get a more detailed log of twirp calls, add this code to the initializer.

```ruby
# config/initializers/twirp_rails.rb
TwirpRails.log_twirp_calls!
```

You can customize log output by pass a block argument

```ruby
# config/initializers/twirp_rails.rb
TwirpRails.log_twirp_calls! do |event|
  twirp_call_info = {
    duration: event.duration,
    method: event.payload[:env][:rpc_method],
    params: event.payload[:env][:input].to_h
  }

  if (exception = event.payload[:env][:exception])
    twirp_call_info[:exception] = exception
  end

  Rails.logger.info "method=%{method} duration=%{duration}" % twirp_call_info
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/severgroup-tt/twirp_rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TwirpRails project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/twirp_rails/blob/master/CODE_OF_CONDUCT.md).
