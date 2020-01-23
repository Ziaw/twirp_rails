module TwirpRails
  module Twirp
    def self.auto_require_twirp_files
      Dir.glob(Rails.root.join('lib/twirp/*_twirp.rb')).sort.each do |file|
        require file
      end
    end
  end
end
