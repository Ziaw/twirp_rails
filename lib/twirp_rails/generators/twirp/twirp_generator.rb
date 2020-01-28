require 'rails/generators'

class TwirpGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  PLUGIN_PATH = ENV.fetch('TWIRP_PLUGIN_PATH') { File.expand_path('~/go/bin/protoc-gen-twirp_ruby') }
  PROTOC_PATH = `which protoc`.chomp

  def check_requirements
    in_root do
      puts `pwd`
      unless File.exists?(proto_file_name)
        raise "#{proto_file_name} not found #{`pwd`} #{`ls`}"
      end
    end

    raise 'protoc not found - install protobuf (brew/apt/yum install protobuf)' unless File.exists?(PROTOC_PATH)

    unless File.exists?(PLUGIN_PATH)
      raise <<~TEXT
        protoc-gen-twirp_ruby not found - install go (brew install go)
        and run "go get github.com/twitchtv/twirp-ruby/protoc-gen-twirp_ruby
        or set TWIRP_PLUGIN_PATH environment variable to right location.
      TEXT
    end
  end

  def generate_twirp_files
    in_root do
      proto_files = Dir.glob 'app/protos/**/*.proto'

      proto_files.each do |file|
        cmd = protoc_cmd(file)

        `#{cmd}`

        raise "protoc failure: #{cmd}" unless $?.success?
      end
    end
  end

  PROTO_RPC_REGEXP = /\brpc\s+(\S+)\s*\(\s*(\S+)\s*\)\s*returns\s*\(\s*(\S+)\s*\)/m.freeze
  def generate_handler
    methods = proto_content.scan(PROTO_RPC_REGEXP).map do |method, arg_type, result_type|
      <<-RUBY
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
    puts 'RSpec TODO'
  end

  private

  def from_rails_root(&block)
    old_dir = Dir.pwd
    Dir.chdir Rails.root
    yield
  ensure
    Dir.chdir old_dir
  end

  def protoc_cmd(files)
    FileUtils.mkdir_p 'lib/twirp'
    flags = "--proto_path=app/protos --ruby_out=lib/twirp --twirp_ruby_out=lib/twirp --plugin=#{PLUGIN_PATH}"

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
end
