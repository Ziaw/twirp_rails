require 'rails/generators'

class TwirpGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :skip_swagger, type: :boolean, default: false
  class_option :swagger_out, type: :string, default: 'public/swagger'

  GO_BIN_PATH = ENV.fetch('GOPATH') { File.expand_path('~/go/bin') }
  TWIRP_PLUGIN_PATH = ENV.fetch('TWIRP_PLUGIN_PATH') { File.join(GO_BIN_PATH, 'protoc-gen-twirp_ruby') }
  SWAGGER_PLUGIN_PATH = ENV.fetch('SWAGGER_PLUGIN_PATH') { File.join(GO_BIN_PATH, 'protoc-gen-twirp_swagger') }
  PROTOC_PATH = `which protoc`.chomp

  def check_requirements
    in_root do
      unless File.exist?(proto_file_name)
        raise "#{proto_file_name} not found #{`pwd`} #{`ls`}"
      end
    end

    raise 'protoc not found - install protobuf (brew/apt/yum install protobuf)' unless File.exist?(PROTOC_PATH)

    unless File.exist?(TWIRP_PLUGIN_PATH)
      raise <<~TEXT
        protoc-gen-twirp_ruby not found - install go (brew install go)
        and run "go get github.com/twitchtv/twirp-ruby/protoc-gen-twirp_ruby
        or set TWIRP_PLUGIN_PATH environment variable to right location.
      TEXT
    end

    if gen_swagger? && !File.exist?(SWAGGER_PLUGIN_PATH)
      raise <<~TEXT
        protoc-gen-twirp_swagger not found - install go (brew install go)
        and run "go get github.com/elliots/protoc-gen-twirp_swagger
        or set SWAGGER_PLUGIN_PATH environment variable to right location.
      TEXT
    end
  end

  def generate_twirp_files
    in_root do
      proto_files = Dir.glob 'app/protos/**/*.proto'

      proto_files.each do |file|
        gen_swagger = gen_swagger? && file =~ %r{/#{file_name}\.proto$}
        pp [gen_swagger, file]
        cmd = protoc_cmd(file, gen_swagger: gen_swagger)

        `#{cmd}`

        raise "protoc failure: #{cmd}" unless $?.success?
      end
    end
  end

  PROTO_RPC_REGEXP = /\brpc\s+(\S+)\s*\(\s*(\S+)\s*\)\s*returns\s*\(\s*(\S+)\s*\)/m.freeze

  def generate_handler
    methods = proto_content.scan(PROTO_RPC_REGEXP).map do |method, arg_type, result_type|
      result_type = proto_type_to_ruby(result_type)
      optimize_indentation <<~RUBY, 2
        def #{method.underscore}(req, _env)
          #{result_type}.new
        end
      RUBY
    end.join("\n")

    # Let us assume that the service name is the same file name
    create_file "app/rpc/#{file_name}_handler.rb", <<~RUBY
      class #{class_name}Handler

      #{methods}end
    RUBY
  end

  def generate_route
    route "mount_twirp :#{file_name}"
  end

  def generate_rspec_files
    in_root do
      return unless File.exist?('spec')

      methods = proto_content.scan(PROTO_RPC_REGEXP).map do |method, arg_type, result_type|
        result_type = proto_type_to_ruby(result_type)
        optimize_indentation <<~RUBY, 2
          context '##{method.underscore}' do
            rpc { [:#{method.underscore}, 'arg'] }

            it do
              expect { #{result_type}.new(subject) }.to_not raise_exception
              should match({})
            end
          end
        RUBY
      end.join("\n")

      create_file "spec/rpc/#{file_name}_handler_spec.rb", <<~RUBY
        require 'rails_helper'

        describe #{class_name}Handler do

        #{methods}end
      RUBY
    end
  end

  def inject_rspec_helper
    in_root do
      return unless File.exist?('spec/rails_helper.rb')

      require_sentinel = %r{require 'rspec/rails'\s*\n}m
      include_sentinel = /RSpec\.configure do |config|\s*\n/m

      inject_into_file 'spec/rails_helper.rb',
                       "require 'twirp/rails/rspec/helper'",
                       after: require_sentinel, verbose: true, force: false
      inject_into_file 'spec/rails_helper.rb',
                       '  config.include TwirpRails::RSpec::Helper, type: :rpc, file_path: %r{spec/rpc}',
                       after: include_sentinel, verbose: true, force: false
    end
  end

  private

  def proto_type_to_ruby(result_type)
    result_type.split('.').map(&:camelize).join('::')
  end

  def protoc_cmd(files, gen_swagger: gen_swagger?)
    FileUtils.mkdir_p 'lib/twirp'

    flags = '--proto_path=app/protos ' \
            '--ruby_out=lib/twirp --twirp_ruby_out=lib/twirp ' \
            "--plugin=#{TWIRP_PLUGIN_PATH}"

    if gen_swagger
      FileUtils.mkdir_p options[:swagger_out]

      flags += " --plugin=#{SWAGGER_PLUGIN_PATH}" \
               " --twirp_swagger_out=#{options[:swagger_out]}"
    end

    "#{PROTOC_PATH} #{flags} #{files}"
  end

  def proto_content
    unless @proto_content
      in_root do
        @proto_content = File.read proto_file_name
      end
    end
    @proto_content
  end

  def proto_file_name
    "app/protos/#{file_name}.proto"
  end

  def gen_swagger?
    !options[:skip_swagger]
  end
end
