TwirpRails.configure do |config|
  # Application services proto files path
  # config.services_proto_path = 'rpc'
  #
  # Used clients proto files path
  # config.clients_proto_path = 'rpc_clients'
  #
  # Services code generator destination path (autorequired on application start)
  # config.services_twirp_code_path = 'lib/twirp'
  #
  # Clients code generator destination path (autorequired on application start)
  # config.clients_twirp_code_path = 'lib/twirp_clients'
  #
  # Swagger files generated from services proto files path (set to nil unless you need to generete swagger)
  # config.swagger_output_path = 'public/swagger'
  #
  # Instrument twirp calls and set hooks to log twirp calls
  # set to proc to customize log output
  # set to false to disable feature
  # config.log_twirp_calls = true
  #
  # Delete all files from x_twirp_code_path
  # before run protoc on proto files
  # config.purge_old_twirp_code = true
  #
  # Add API acronym to inflector
  # config.add_api_acronym = true
  #
  # Translate exceptions to Twirp::Error on services and
  # Twirp::Error to exceptions. To use service translation you
  # should mount service via mount_twirp. To use client translation
  # create client via TwirpRails.client(ClientClass, url) and
  # call bang methods. E.g. client.hello! throws exception if returns error.
  #
  # class SampleTranslator < TwirpRails::ErrorHandling::Base
  #   translate_exception Mongoid::Errors::DocumentNotFound, with: :not_found
  #   translate_error :not_found, with: Mongoid::Errors::DocumentNotFound
  # end
  # config.twirp_exception_translator_class = 'SampleTranslator'
  # default:
  # config.twirp_exception_translator_class = nil
end
