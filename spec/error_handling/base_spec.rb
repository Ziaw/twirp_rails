require 'spec_helper'
require 'twirp_rails'

RSpec.describe TwirpRails::ErrorHandling::Base do
  class ErrorHandlingTest < TwirpRails::ErrorHandling::Base
    translate_exception ArgumentError, with: :invalid_argument
    translate_error :invalid_argument, with: ArgumentError
  end

  it 'can translate exception to twirp' do
    err = ErrorHandlingTest.exception_to_twirp(ArgumentError.new('x'), nil)
    expected = Twirp::Error.invalid_argument('x')

    expect(err.code).to eq(expected.code)
    expect(err.msg).to eq(expected.msg)
  end

  it 'can translate twirp to exception' do
    expect(ErrorHandlingTest.twirp_to_exception(Twirp::Error.invalid_argument('x'), nil))
      .to eq(ArgumentError.new('x'))
  end

  it 'can translate twirp to exception' do
    expect(ErrorHandlingTest.twirp_to_exception(Twirp::Error.invalid_argument('x'), nil))
      .to eq(ArgumentError.new('x'))
  end
end
