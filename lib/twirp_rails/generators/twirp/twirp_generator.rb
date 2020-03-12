require 'rails/generators'

class TwirpGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :skip_swagger, type: :boolean, default: false
  class_option :swagger_out, type: :string, default: 'public/swagger'

  GOPATH = ENV.fetch('GOPATH') { File.expand_path('~/go') }
  GO_BIN_PATH = File.join(GOPATH, 'bin')
  TWIRP_PLUGIN_PATH = ENV.fetch('TWIRP_PLUGIN_PATH') { File.join(GO_BIN_PATH, 'protoc-gen-twirp_ruby') }
  SWAGGER_PLUGIN_PATH = ENV.fetch('SWAGGER_PLUGIN_PATH') { File.join(GO_BIN_PATH, 'protoc-gen-twirp_swagger') }
  PROTOC_PATH = `which protoc`.chomp

  def check_requirements
    in_root do
      unless File.exist?(proto_file_name)
        raise "#{proto_file_name} not found"
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
      protos_mask = File.join *['app/protos', class_path, '**/*.proto'].flatten
      proto_files = Dir.glob protos_mask

      proto_files.each do |file|
        gen_swagger = gen_swagger? && file =~ %r{/#{file_name}\.proto$}

        cmd = protoc_cmd(file, gen_swagger: gen_swagger)

        `#{cmd}`

        raise "protoc failure: #{cmd}" unless $?.success?
      end
    end
  end

  PROTO_RPC_REGEXP = /\brpc\s+(\S+)\s*\(\s*(\S+)\s*\)\s*returns\s*\(\s*(\S+)\s*\)/m.freeze

  def create_module_files
    return if regular_class_path.empty?

    class_path.length.times do |i|
      current_path = class_path[0..i]
      create_file File.join('app/rpc', "#{current_path.join('/')}.rb"),
                  module_hier(current_path.map(&:camelize), 0)
    end
  end

  def generate_handler
    methods = proto_content.scan(PROTO_RPC_REGEXP).map do |method, _arg_type, _result_type|
      optimize_indentation <<~RUBY, 2
        def #{method.underscore}(req, _env)
        end
      RUBY
    end.join("\n")

    # Let us assume that the service name is the same file name
    create_file "app/rpc/#{file_path}_handler.rb", <<~RUBY
      class #{class_name}Handler
      #{methods}end
    RUBY
  end

  def generate_route
    route "mount_twirp '#{file_path}'"
  end

  def generate_rspec_files
    in_root do
      return unless File.exist?('spec')

      methods = proto_content.scan(PROTO_RPC_REGEXP).map do |method, _arg_type, result_type|
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

      create_file "spec/rpc/#{file_path}_handler_spec.rb", <<~RUBY
        require 'rails_helper'

        describe #{class_name}Handler do

        #{methods}end
      RUBY
    end
  end

  private

  def module_hier(modules, indent)
    return '' if modules.size.zero?

    cur, *tail = modules
    optimize_indentation <<~RUBY, indent
      module #{cur}
      #{module_hier(tail, indent + 2)}end
    RUBY
  end

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
    "app/protos/#{file_path}.proto"
  end

  def gen_swagger?
    !options[:skip_swagger]
  end
end
