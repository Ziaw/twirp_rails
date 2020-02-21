require 'action_dispatch'

module TwirpRails
  module Routes # :nodoc:
    module Helper
      def mount_twirp(name, handler: nil, scope: 'twirp')
        case name
        when Class
          raise 'handler param required when name is a class' unless handler&.is_a?(Class)

          service_class = name

        when String, Symbol
          service_class = Helper.constantize_first "#{name}_service", name

          raise "#{name.camelize}Service or #{name.camelize} is not found" unless service_class

          handler ||= "#{name}_handler".camelize.constantize

        else
          raise 'twirp service name required'
        end

        service = service_class.new(handler.new)
        Helper.run_create_hooks service

        if scope
          scope scope do
            mount service, at: service.full_name
          end
        else
          mount service, at: service.full_name
        end
      end

      def self.constantize_first(*variants)
        variants.each do |name|
          clazz = name.to_s.camelize.constantize

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
