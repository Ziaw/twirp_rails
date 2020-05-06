require 'action_dispatch'

module TwirpRails
  module Routes # :nodoc:
    module Helper
      def mount_twirp(name, handler: nil, scope: 'twirp')
        TwirpRails.handle_dev_error "mount twirp route #{name}" do
          case name
          when Class
            raise 'handler param required when name is a class' unless handler&.is_a?(Class)

            service_class = name

          when String, Symbol
            service_class = Helper.constantize_first "#{name}_service", name

            unless service_class
              msg = "mount_twirp of #{name} error. #{name.camelize}Service or #{name.camelize} class is not found"

              raise TwirpRails::Error, msg
            end

            handler ||= "#{name}_handler".camelize.constantize
          else
            raise 'twirp service name required'
          end

          service = service_class.new(ErrorHandlingFactory.wrap_handler(handler.new))
          Helper.run_create_hooks service

          if scope
            scope scope do
              mount service, at: service.full_name
            end
          else
            mount service, at: service.full_name
          end
        end
      end

      def self.constantize_first(*variants)
        variants.each do |name|
          clazz = name.to_s.camelize.safe_constantize

          return clazz if clazz
        end

        nil
      end

      def self.install
        ActionDispatch::Routing::Mapper.include TwirpRails::Routes::Helper
      end

      cattr_accessor :create_service_hooks

      def self.on_create_service(&block)
        Helper.create_service_hooks ||= []
        Helper.create_service_hooks << block
      end

      def self.run_create_hooks(service)
        return unless Helper.create_service_hooks

        Helper.create_service_hooks.each do |hook|
          hook.call service
        end
      end
    end
  end
end
