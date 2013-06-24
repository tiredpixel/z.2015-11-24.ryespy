require 'redis'


module Ryespy
  class RedisConn
    
    def initialize
      begin
        @redis = Redis.connect(:url => Ryespy.config.redis_url)
        
        @redis.ping
      rescue Redis::CannotConnectError => e
        Ryespy.logger.error { e.to_s }
        
        return
      end
      
      if block_given?
        yield @redis
        
        close
      end
    end
    
    def close
      @redis.quit
    end
    
    def add
      @redis.add("")
    end
    
  end
end
