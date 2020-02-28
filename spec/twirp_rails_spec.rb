require 'spec_helper'

RSpec.describe TwirpRails do
  it 'has a version number' do
    expect(TwirpRails::VERSION).not_to be nil
  end

  context 'can instrument rails logs' do
    before do
      allow(TwirpRails::LoggingAdapter).to receive(:install)
      allow(TwirpRails::LogSubscriber).to receive(:attach_to).with(:twirp)
    end

    it { TwirpRails.log_twirp_calls! }
  end
end
