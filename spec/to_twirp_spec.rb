require 'rails_helper'
require 'twirp_rails/active_record_extension'

RSpec.describe 'to_twirp' do
  class TestClass
    include TwirpRails::ActiveRecordExtension

    twirp_message GetNameRequest

    attr_accessor :uid

    def attributes
      {
        'uid' => uid
      }
    end
  end

  context '#to_twirp' do
    let!(:model) { TestClass.new.tap { |m| m.uid = 'xxx' } }

    it { expect(model.to_twirp).to match('uid' => 'xxx') }
  end

end
