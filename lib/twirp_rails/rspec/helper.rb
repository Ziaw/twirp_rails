module TwirpRails
  module RSpec
    module Helper
      extend ActiveSupport::Concern

      module ClassMethods
        # places to subject service method returned value converted to_h
        # @param [Boolean] to_h - default true, set to false to use pure result
        # @param [Proc] block - should return array with method name and arguments
        # @example
        #   rpc { [:get, id: 1] }
        #   it { should match(id: 1)}
        def rpc(to_h: true, &block)
          let :rpc_args, &block
          subject do
            result = service.call_rpc(*rpc_args)
            to_h ? result.to_h : result
          end
        end

        def service_class_from_describe
          result = metadata[:service]

          result = result.constantize if result && !result.is_a?(Class)

          result
        end

        def infer_service_class
          service_class_name = described_class.name.gsub(/Handler$/, '') + 'Service'

          service_class_name.constantize
        rescue NameError
          msg = "Cannot infer Service class from handler #{described_class.name}."
          msg += " Inferred name #{service_class_name}" if service_class_name

          raise msg
        end

        def service_class
          @service_class ||=
            service_class_from_describe || infer_service_class
        end
      end

      def service_class
        self.class.service_class
      end

      included do
        let(:handler) { described_class.new }
        let(:service) { service_class.new(handler) }
      end
    end
  end
end
