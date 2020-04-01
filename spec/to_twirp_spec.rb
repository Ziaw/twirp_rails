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

    def custom_method1
      'custom_method_response1'
    end

    def custom_method2
      'custom_method_response2'
    end

    def custom_method3
      'custom_method_response3'
    end
  end

  describe '#to_twirp' do
    let!(:model) { TestClass.new.tap { |m| m.uid = 'xxx' } }

    context 'empty' do
      it { expect(model.to_twirp).to match('uid' => 'xxx') }
    end

    context 'attributes' do
      it { expect(model.to_twirp('uid')).to match('uid' => 'xxx') }
    end

    context 'wrong attributes' do
      it { expect{model.to_twirp('blah')}.to raise_error(NoMethodError) }
    end


    context 'custom_methods' do
      it do
        expect(model.to_twirp('custom_method1', 'custom_method2')).to(
          match(
            'custom_method1' => 'custom_method_response1',
            'custom_method2' => 'custom_method_response2'
          )
        )
      end

      context 'with twirp_message Class' do
        it do
          expect(model.to_twirp(GetNameExtendedResponse)).to(
            match(
              'uid' => 'xxx',
              'custom_method1' => 'custom_method_response1',
              'custom_method2' => 'custom_method_response2',
              'custom_method3' => 'custom_method_response3'
            )
          )
        end
      end
    end
  end
end
