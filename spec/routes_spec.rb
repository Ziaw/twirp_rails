require 'rails_helper'
require 'twirp_rails/routes'
require 'twirp'

RSpec.describe TwirpRails::Routes::Helper, type: :routing do
  let(:people_route_exists) { @routes.routes.any? { |r| r.path.spec.to_s == '/People' } }

  it { expect(people_route_exists).to be_truthy }
end
