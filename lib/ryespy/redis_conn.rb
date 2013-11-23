require 'logger'
require 'redis'


module Ryespy
  class RedisConn
    
    attr_accessor :redis
    
    def initialize(url = nil, opts = {})
      @logger = opts[:logger] || Logger.new(nil)
      
      begin
        @redis = Redis.connect(:url => url)
        
        @redis.ping
      rescue Redis::CannotConnectError => e
        @logger.error { e.to_s }
        
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
