# TwirpRails

TwirpRails used to easy embed of [twirp-ruby gem](https://github.com/twitchtv/twirp-ruby) to rails stack and
automate code generation from ```.proto``` files.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'twirp_rails'
```

See the [twirp-ruby code generation documentation](https://github.com/twitchtv/twirp-ruby/wiki/Code-Generation) 
for install required protoc and twirp-ruby plugin.

## Usage

### Generator

Create proto file ```app/protos/people.proto```:
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
```

This command generates ```lib/twirp/people_pb.rb```, ```lib/twirp/people_twirp.rb``` and ```app/rpc/people_handler.rb``` and adds route.
```ruby
# app/rpc/people_handler.rb

class PeopleHandler

  def get_name(req, _env)
    GetNameResponse.new
  end
end
```

### Call RPC

Modify app/rpc/people_handler.rb:
```ruby
  def get_name(req, _env)
    GetNameResponse.new name: "Name of #{req.uid}"
  end
```

Run rails server
```sh
rails s
```

And test from rails console.
```ruby
PeopleClient.new('http://localhost:3000').get_name(GetNameRequest.new uid: '1').data.name
=> "Name of 1"
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
