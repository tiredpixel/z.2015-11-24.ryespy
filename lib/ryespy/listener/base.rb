require 'logger'
require 'redis'


module Ryespy
  module Listener
    class Base
      
      def initialize(opts = {})
        @notifiers = opts[:notifiers] || []
        @logger    = opts[:logger] || Logger.new(nil)
        
        @redis = Redis.current
        
        connect_service
        
        if block_given?
          yield self
          
          close
        end
      end
      
      def close
      end
      
      private
      
      def connect_service
      end
      
    end
  end
end
