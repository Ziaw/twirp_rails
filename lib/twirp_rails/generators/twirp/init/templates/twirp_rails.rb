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
end
