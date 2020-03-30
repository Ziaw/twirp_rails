require 'rails/generators'

class TwirpGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :skip_swagger, type: :boolean, default: false
  class_option :swagger_out, type: :string, default: nil

  GOPATH = ENV.fetch('GOPATH') { File.expand_path('~/go') }
  GO_BIN_PATH = File.join(GOPATH, 'bin')
  TWIRP_PLUGIN_PATH = ENV.fetch('TWIRP_PLUGIN_PATH') { File.join(GO_BIN_PATH, 'protoc-gen-twirp_ruby') }
  SWAGGER_PLUGIN_PATH = ENV.fetch('SWAGGER_PLUGIN_PATH') { File.join(GO_BIN_PATH, 'protoc-gen-twirp_swagger') }
  PROTOC_PATH = `which protoc`.chomp

  def smart_detect_proto_file_name
    return if File.exist?(proto_file_name) # dont detect when file exists
    return if class_path.any? # dont detect when file with path

    in_root do
      [file_name, "#{file_name}_api"].each do |file|
        mask = File.join src_path, "**/#{file}.proto"
        matched_files = Dir.glob(mask)

        next if matched_files.empty?

        abort "many proto files matched the #{file_name}: #{matched_files.join(' ')}" if matched_files.size > 1

        matched_file = Pathname.new(matched_files.first).relative_path_from Pathname.new(src_path)
        matched_file = matched_file.to_s[0..-(matched_file.extname.length + 1)] # remove extension

        @file_path = nil # reset cache
        assign_names!(matched_file)
        break
      end
    end
  end

  def check_requirements
    in_root do
      abort "#{proto_file_name} not found" unless File.exist?(proto_file_name)
    end

    unless File.exist?(PROTOC_PATH)
      abort 'protoc not found - install protobuf (brew/apt/yum install protobuf)'
    end

    unless File.exist?(TWIRP_PLUGIN_PATH)
      abort <<~TEXT
        protoc-gen-twirp_ruby not found - install go (brew install go)
        and run "go get github.com/twitchtv/twirp-ruby/protoc-gen-twirp_ruby
        or set TWIRP_PLUGIN_PATH environment variable to right location.
      TEXT
    end

    if gen_swagger? && !File.exist?(SWAGGER_PLUGIN_PATH)
      abort <<~TEXT
        protoc-gen-twirp_swagger not found - install go (brew install go)
        and run "go get github.com/elliots/protoc-gen-twirp_swagger
        or set SWAGGER_PLUGIN_PATH environment variable to right location.
      TEXT
    end
  end

  def rm_old_twirp_files
    return unless cfg.purge_old_twirp_code

    in_root do
      return unless File.exists? dst_path

      remove_mask = File.join dst_path, '**/*_{twirp,pb}.rb'
      files_to_remove = Dir.glob remove_mask

      return if files_to_remove.empty?

      files_to_remove.each do |file|
        File.unlink file
      end

      msg = "#{files_to_remove.size} twirp and pb files purged from #{dst_path}"
      say_status :protoc, msg, :green
    end
  end

  def generate_twirp_files
    in_root do
      FileUtils.mkdir_p dst_path

      protos_mask = File.join src_path, '**/*.proto'
      proto_files = Dir.glob protos_mask

      protoc_files_count = 0
      swagger_files_count = 0

      proto_files.each do |file|
        gen_swagger = gen_swagger? && file =~ %r{/#{file_name}\.proto$}

        FileUtils.mkdir_p swagger_out_path if gen_swagger

        cmd = protoc_cmd(file, gen_swagger: gen_swagger)

        protoc_files_count += 1
        swagger_files_count += gen_swagger ? 1 : 0

        `#{cmd}`

        abort "protoc failure: #{cmd}" unless $?.success?
      end

      msg = "#{protoc_files_count} proto files processed, #{swagger_files_count} with swagger"
      say_status :protoc, msg, :green
    end
  end

  PROTO_RPC_REGEXP = /\brpc\s+(\S+)\s*\(\s*(\S+)\s*\)\s*returns\s*\(\s*(\S+)\s*\)/m.freeze

  def create_module_files
    return if regular_class_path.empty?

    class_path.length.times do |i|
      current_path = class_path[0..i]

      create_file File.join('app/rpc', "#{current_path.join('/')}.rb"), <<~RUBY
        # :nocov:
        #{module_hier(current_path.map(&:camelize))}# :nocov:
      RUBY
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

  def module_hier(modules, indent = 0)
    return '' if modules.size.zero?

    cur, *tail = modules
    optimize_indentation <<~RUBY, indent
      module #{cur}
      #{module_hier(tail, 2)}end
    RUBY
  end

  def proto_type_to_ruby(result_type)
    result_type.split('.').map(&:camelize).join('::')
  end

  def protoc_cmd(files, gen_swagger: gen_swagger?)
    flags = "--proto_path=#{src_path} " \
            "--ruby_out=#{dst_path} --twirp_ruby_out=#{dst_path} " \
            "--plugin=#{TWIRP_PLUGIN_PATH}"

    if gen_swagger
      flags += " --plugin=#{SWAGGER_PLUGIN_PATH}" \
               " --twirp_swagger_out=#{swagger_out_path}"
    end

    "#{PROTOC_PATH} #{flags} #{files}"
  end

  def src_path
    cfg.services_proto_path
  end

  def dst_path
    cfg.services_twirp_code_path
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
    File.join src_path, "#{file_path}.proto"
  end

  def cfg
    TwirpRails.configuration
  end

  def gen_swagger?
    !options[:skip_swagger] && cfg.swagger_output_path
  end

  def swagger_out_path
    options[:swagger_out] || cfg.swagger_output_path
  end

  def abort(msg)
    raise Thor::InvocationError, msg
  end
end
