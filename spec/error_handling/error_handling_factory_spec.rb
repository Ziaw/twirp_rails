require 'spec_helper'
require 'twirp_rails'

RSpec.describe TwirpRails::ErrorHandlingFactory do
  class ErrorHandlingFactoryTest < TwirpRails::ErrorHandling::Base
    translate_exception ArgumentError, with: :invalid_argument
    translate_error :invalid_argument, with: ArgumentError
  end

  class HandlerSample
    def success(_req, _env)
      {}
    end

    def fail(_req, _env)
      raise ArgumentError, 'error'
    end
  end

  class ClientSample
    def success(_arg)
      Twirp::ClientResp.new({}, nil)
    end

    def fail(_arg)
      Twirp::ClientResp.new(nil, Twirp::Error.invalid_argument('error'))
    end
  end

  context 'with handling on' do
    before :each do
      allow(TwirpRails::ErrorHandlingFactory).to receive(:enable_handling?).and_return(true)
      allow(TwirpRails::ErrorHandlingFactory).to receive(:translator_class).and_return(ErrorHandlingFactoryTest)
    end

    let(:handler) { HandlerSample.new }
    let(:client) { ClientSample.new }
    let(:w_handler) { TwirpRails::ErrorHandlingFactory.wrap_handler(handler) }
    let(:w_client) { TwirpRails::ErrorHandlingFactory.wrap_client(client) }

    it do
      expect(w_handler.success(nil, nil)).to eq({})

      w_handler_fail = w_handler.fail(nil, nil)
      expect(w_handler_fail).to be_is_a(::Twirp::Error)
      expect(w_handler_fail.code).to eq(:invalid_argument)
      expect(w_handler_fail.msg).to eq('error')

      expect(w_client.success({}).error).to be_nil
      expect(w_client.success({}).data).to eq({})

      expect(w_client.success!({}).error).to be_nil
      expect(w_client.success!({}).data).to eq({})

      expect(w_client.fail({}).error).to be_present
      expect(w_client.fail({}).data).to be_nil

      expect { w_client.fail!({}) }.to raise_exception(ArgumentError)
    end
  end

  context 'with handling off' do
    before :each do
      allow(TwirpRails::ErrorHandlingFactory).to receive(:enable_handling?).and_return(false)
      allow(TwirpRails::ErrorHandlingFactory).to receive(:translator_class).and_return(nil)
    end

    let(:handler) { HandlerSample.new }
    let(:client) { ClientSample.new }
    let(:w_handler) { TwirpRails::ErrorHandlingFactory.wrap_handler(handler) }
    let(:w_client) { TwirpRails::ErrorHandlingFactory.wrap_client(client) }

    it do
      expect(w_handler.success(nil, nil)).to eq({})

      expect { w_handler.fail(nil, nil) }.to raise_exception(ArgumentError)

      expect(w_client.success({}).error).to be_nil
      expect(w_client.success({}).data).to eq({})

      expect { w_client.success!({}) }.to raise_exception(NoMethodError)

      expect(w_client.fail({}).error).to be_present
      expect(w_client.fail({}).data).to be_nil

      expect { w_client.fail!({}) }.to raise_exception(NoMethodError)
    end
  end
end
