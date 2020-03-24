require 'rails/generators'

module Twirp
  class ClientsGenerator < Rails::Generators::Base
    desc 'This generator run protoc generation on each file in the twirp_clients dir'

    def check_requirements
      raise 'protoc not found - install protobuf (brew/apt/yum install protobuf)' unless File.exist?(TwirpGenerator::PROTOC_PATH)

      unless File.exist?(TwirpGenerator::TWIRP_PLUGIN_PATH)
        raise <<~TEXT
          protoc-gen-twirp_ruby not found - install go (brew install go)
          and run "go get github.com/twitchtv/twirp-ruby/protoc-gen-twirp_ruby
          or set TWIRP_PLUGIN_PATH environment variable to right location.
        TEXT
      end
    end

    def generate_twirp_files
      in_root do
        FileUtils.mkdir_p cfg.clients_twirp_code_path

        protos_mask = File.join cfg.clients_proto_path, '**/*.proto'
        proto_files = Dir.glob protos_mask

        proto_files.each do |file|
          cmd = protoc_cmd(file)

          `#{cmd}`

          raise "protoc failure: #{cmd}" unless $?.success?
        end
      end
    end

    private

    def cfg
      TwirpRails.configuration
    end

    def protoc_cmd(files)
      flags = "--proto_path=#{cfg.clients_proto_path} " \
            "--ruby_out=#{cfg.clients_twirp_code_path} --twirp_ruby_out=#{cfg.clients_twirp_code_path} " \
            "--plugin=#{TwirpGenerator::TWIRP_PLUGIN_PATH}"

      "#{TwirpGenerator::PROTOC_PATH} #{flags} #{files}"
    end

  end
end
