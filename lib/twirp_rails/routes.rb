module TwirpRails
  class Routes # :nodoc:
    module Helper
      def mount_twirp(name, handler: nil)
        case name
        when Class
          raise 'handler param required when name is a class' unless handler&.is_a?(Class)

          service_class = name

        when String, Symbol
          service_class = "#{name}_service".camelize.constantize rescue name.camelize.constantize
          handler ||= "#{name}_handler".camelize.constantize

        else
          raise 'twirp service name required'
        end

        service = service_class.new(handler.new)
        mount service, at: service.full_name
      end

      def self.install
        ActionDispatch::Routing::Mapper.send :include, TwirpRails::Routes::Helper
      end
    end
  end
end
