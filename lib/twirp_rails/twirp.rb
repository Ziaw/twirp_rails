module TwirpRails
  module Twirp
    def self.auto_require_twirp_files(twirp_path)
      # protoc generates require without path in a _pb files
      $LOAD_PATH.unshift(twirp_path) unless $LOAD_PATH.include?(twirp_path)

      Dir.glob(Rails.root.join(twirp_path, '**/*_twirp.rb')).sort.each do |file|
        require file
      end
    end
  end
end
