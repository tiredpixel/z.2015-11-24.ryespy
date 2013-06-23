module Ryespy
  class Config
    
    attr_accessor :log_level
    
    attr_accessor :polling_interval
    
    def initialize
      @log_level = 'INFO'
      
      @polling_interval = 60
    end
    
    def to_s
      {
        :log_level => @log_level,
        
        :polling_interval => @polling_interval,
      }.to_s
    end
    
  end
end
