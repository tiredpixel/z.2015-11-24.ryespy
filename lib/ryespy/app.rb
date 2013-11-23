require 'logger'


module Ryespy
  class App
    
    def config
      @config ||= Config.new
    end
    
    def configure
      yield config
      
      logger.debug { "Configured #{config.to_s}" }
    end
    
    def logger
      unless @logger
        @logger = Logger.new($stdout)
        
        @logger.level = Logger.const_get(config.log_level)
      end
      
      @logger
    end
    
    def redis
      @redis ||= Ryespy::RedisConn.new(config.redis_url,
        :logger => logger
      ).redis
    end
    
    def notifiers
      unless @notifiers
        @notifiers = []
        
        config.notifiers[:sidekiq].each do |notifier_instance|
          @notifiers << Ryespy::Notifier::Sidekiq.new(notifier_instance,
            :config => config,
            :logger => logger
          )
        end
      end
      
      @notifiers
    end
    
  end
end
