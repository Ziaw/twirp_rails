
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'twirp_rails/version'

Gem::Specification.new do |spec|
  spec.name          = 'twirp_rails'
  spec.version       = TwirpRails::VERSION
  spec.authors       = ['Alexandr Zimin']
  spec.email         = ['a.zimin@talenttech.ru']

  spec.summary       = %q{Use twirp-ruby from rails.}
  spec.homepage      = 'https://github.com/severgroup-tt/twirp_rails'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(\.cicleci|bin|test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'twirp', '~> 1'
  spec.add_dependency 'railties', '~> 6.0'

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-rails', '~> 3.0'
  spec.add_development_dependency 'generator_spec', '~> 0.9'
  spec.add_development_dependency 'pry', '~> 0.12'
end
