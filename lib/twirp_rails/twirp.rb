module TwirpRails
  module Twirp
    def self.auto_require_twirp_files
      # protoc generates require without path in a _pb files
      twirp_path = Rails.root.join('lib/twirp').to_s
      $LOAD_PATH.unshift(twirp_path) if !$LOAD_PATH.include?(twirp_path)

      Dir.glob(Rails.root.join('lib/twirp/*_twirp.rb')).sort.each do |file|
        require file
      end
    end
  end
end
