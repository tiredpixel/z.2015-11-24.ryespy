require 'logger'

require_relative 'ryespy/version'
require_relative 'ryespy/config'


module Ryespy
  
  extend self
  
  def config
    @config ||= Ryespy::Config.new
  end
  
  def configure
    yield config
    
    Ryespy.logger.debug { "Configured #{Ryespy.config.to_s}" }
  end
  
  def logger
    unless @logger
      @logger = Logger.new($stdout)
      
      @logger.level = Logger.const_get(Ryespy.config.log_level)
    end
    
    @logger
  end
  
end
