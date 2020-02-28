module TwirpRails
  class LogSubscriber < ActiveSupport::LogSubscriber
    cattr_accessor :log_writer

    def instrumenter(event)
      if LogSubscriber.log_writer
        LogSubscriber.log_writer.call(event)
      else
        default_log_writer(event)
      end
    end

    def default_log_writer(event)
      twirp_call_info = {
        duration: event.duration,
        method: event.payload[:env][:rpc_method],
        params: event.payload[:env][:input].to_h
      }

      if (exception = event.payload[:env][:exception])
        twirp_call_info[:exception] = exception
      end

      Rails.logger.info twirp_call_info
    end
  end
end
