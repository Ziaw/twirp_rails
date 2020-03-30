require 'rails/generators'

module Twirp
  class ClientsGenerator < Rails::Generators::Base
    desc 'This generator run protoc generation on each file in the twirp_clients dir'

    def check_requirements
      protoc.check_requirements do |msg|
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

        proto_files.each do |file|
          cmd = protoc.cmd(file)

          `#{cmd}`

          abort "protoc failure: #{cmd}" unless $?.success?
        end
      end
    end

    private

    def cfg
      TwirpRails.configuration
    end

    def abort(msg)
      raise Thor::InvocationError, msg
    end

    def protoc
      @protoc ||= ProtocAdapter.new(src_path, dst_path)
    end

    def src_path
      cfg.clients_proto_path
    end

    def dst_path
      cfg.clients_twirp_code_path
    end
  end
end
