class ProtocAdapter
  attr_reader :src_path, :dst_path, :swagger_out_path

  attr_reader :twirp_plugin_path, :swagger_plugin_path, :protoc_path

  def initialize(src_path, dst_path, swagger_out_path: nil)
    @src_path = src_path
    @dst_path = dst_path
    @swagger_out_path = swagger_out_path

    go_path = ENV.fetch('GOPATH') { File.expand_path('~/go') }
    go_bin_path = File.join(go_path, 'bin')
    @twirp_plugin_path = ENV.fetch('TWIRP_PLUGIN_PATH') { File.join(go_bin_path, 'protoc-gen-twirp_ruby') }
    @swagger_plugin_path = ENV.fetch('SWAGGER_PLUGIN_PATH') { File.join(go_bin_path, 'protoc-gen-twirp_swagger') }
    @protoc_path = `which protoc`.chomp
  end

  def rm_old_twirp_files
    return unless File.exists? dst_path

    remove_mask = File.join dst_path, '**/*_{twirp,pb}.rb'
    files_to_remove = Dir.glob remove_mask

    return if files_to_remove.empty?

    files_to_remove.each do |file|
      File.unlink file
    end
  end

  def cmd(files, gen_swagger: false)
    flags = "--proto_path=#{src_path} " \
            "--ruby_out=#{dst_path} --twirp_ruby_out=#{dst_path} " \
            "--plugin=#{twirp_plugin_path}"

    if gen_swagger
      flags += " --plugin=#{swagger_plugin_path}" \
               " --twirp_swagger_out=#{swagger_out_path}"
    end

    "#{protoc_path} #{flags} #{files}"
  end

  def check_requirements(check_swagger: false)
    unless File.exist?(protoc_path)
      yield 'protoc not found - install protobuf (brew/apt/yum install protobuf)'
    end

    unless File.exist?(twirp_plugin_path)
      yield <<~TEXT
        protoc-gen-twirp_ruby not found - install go (brew install go)
        and run "go get github.com/twitchtv/twirp-ruby/protoc-gen-twirp_ruby
        or set TWIRP_PLUGIN_PATH environment variable to right location.
      TEXT
    end

    if check_swagger && !File.exist?(swagger_plugin_path)
      yield <<~TEXT
        protoc-gen-twirp_swagger not found - install go (brew install go)
        and run "go get github.com/elliots/protoc-gen-twirp_swagger
        or set SWAGGER_PLUGIN_PATH environment variable to right location.
      TEXT
    end
  end
end
