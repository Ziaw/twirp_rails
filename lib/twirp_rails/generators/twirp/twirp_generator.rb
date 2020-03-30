require 'rails/generators'

class TwirpGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :skip_swagger, type: :boolean, default: false
  class_option :swagger_out, type: :string, default: nil

  def smart_detect_proto_file_name
    return if File.exist?(proto_file_name) # dont detect when file exists
    return if class_path.any? # dont detect when file with path

    in_root do
      [file_name, "#{file_name}_api"].each do |file|
        mask = File.join src_path, "**/#{file}.proto"
        matched_files = Dir.glob(mask)

        puts 2
        next if matched_files.empty?

        abort "many proto files matched the #{file_name}: #{matched_files.join(' ')}" if matched_files.size > 1

        matched_file = Pathname.new(matched_files.first).relative_path_from Pathname.new(src_path)
        matched_file = matched_file.to_s[0..-(matched_file.extname.length + 1)] # remove extension

        @file_path = nil # reset cache
        puts matched_file
        puts matched_file.camelize
        assign_names!(matched_file)
        break
      end
    end
  end

  def check_requirements
    in_root do
      abort "#{proto_file_name} not found" unless File.exist?(proto_file_name)
    end

    protoc.check_requirements(check_swagger: gen_swagger?) do |msg|
      abort msg
    end
  end

  def rm_old_twirp_files
    return unless cfg.purge_old_twirp_code

    in_root do
      removed_files = protoc.rm_old_twirp_files

      if removed_files
        msg = "#{removed_files.size} twirp and pb files purged from #{dst_path}"
        say_status :protoc, msg, :green
      end
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

        cmd = protoc.cmd(file, gen_swagger: gen_swagger)

        protoc_files_count += 1
        swagger_files_count += gen_swagger ? 1 : 0

        `#{cmd}`

        abort "protoc failure: #{cmd}" unless $?.success?
      end

      msg = "#{protoc_files_count} proto files processed, #{swagger_files_count} with swagger"
      say_status :protoc, msg, :green
    end
  end

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

  PROTO_RPC_REGEXP = /\brpc\s+(\S+)\s*\(\s*(\S+)\s*\)\s*returns\s*\(\s*(\S+)\s*\)/m.freeze

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

  def protoc
    @protoc ||= ProtocAdapter.new(src_path, dst_path, swagger_out_path: swagger_out_path)
  end
end
