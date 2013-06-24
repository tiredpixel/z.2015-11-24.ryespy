require 'redis'


module Ryespy
  class RedisConn
    
    attr_accessor :redis
    
    def initialize(url = nil)
      begin
        @redis = Redis.connect(:url => url)
        
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
    
  end
end
