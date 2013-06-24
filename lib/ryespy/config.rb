module Ryespy
  class Config
    
    attr_accessor :log_level
    attr_accessor :polling_interval
    attr_accessor :redis_url
    attr_accessor :redis_ns_ryespy
    
    def initialize
      @log_level        = 'INFO'
      @polling_interval = 60
      @redis_ns_ryespy  = 'ryespy:'
    end
    
    def to_s
      params = [
        :log_level,
        :polling_interval,
        :redis_url,
        :redis_ns_ryespy,
      ]
      
      params.collect! { |s| [s, instance_variable_get("@#{s}")] }
      
      Hash[params].to_s
    end
    
  end
end
