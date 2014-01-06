require 'logger'


module Ryespy
  class App
    
    attr_reader :config
    attr_reader :running
    
    def initialize(eternal = false, opts = {})
      @eternal = eternal
      
      @logger = opts[:logger] || Logger.new(nil)
      
      @config = Config.new
      
      @running = false
      @threads = {}
    end
    
    def configure
      yield @config
      
      @logger.level = Logger.const_get(@config.log_level)
      
      @logger.debug { "Configured #{@config.to_s}" }
    end
    
    def redis
      @redis ||= RedisConn.new(@config.redis_url,
        :logger => @logger
      ).redis
    end
    
    def notifiers
      unless @notifiers
        @notifiers = []
        
        @config.notifiers[:sidekiq].each do |notifier_instance|
          @notifiers << Notifier::Sidekiq.new(notifier_instance,
            :config => @config,
            :logger => @logger
          )
        end
      end
      
      @notifiers
    end
    
    def start
      begin
        @running = true
        
        setup
        
        @threads[:refresh] ||= Thread.new do
          refresh_loop # refresh frequently
        end
        
        @threads.values.each(&:join)
      ensure
        cleanup
      end
    end
    
    def stop
      @running = false
      
      @threads.values.each { |t| t.run if t.status == 'sleep' }
    end
    
    private
    
    def setup
    end
    
    def cleanup
    end
    
    def refresh_loop
      while @running do
        {
          'imap' => Listener::IMAP,
          'ftp'  => Listener::FTP,
        }[@config.listener.to_s].new(
          :config    => @config,
          :redis     => redis,
          :notifiers => notifiers,
          :logger    => @logger
        ) do |listener|
          listener.check_all
        end
        
        if !@eternal
          stop
          
          break
        end
        
        @logger.debug { "Snoring for #{@config.polling_interval} s" }
        
        sleep @config.polling_interval # sleep awhile (snore)
      end
    end
    
  end
end
