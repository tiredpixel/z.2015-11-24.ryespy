require 'logger'
require 'ostruct'
require 'redis'
require 'redis-namespace'

# listener dynamically required in App#setup


module Ryespy
  class App
    
    def self.config_defaults
      {
        :log_level          => :INFO,
        :polling_interval   => 60,
        :redis_ns_ryespy    => 'ryespy',
        :redis_ns_notifiers => 'resque',
        :imap => {
          :port    => 993,
          :ssl     => true,
          :filters => ['INBOX'], # mailboxes
        },
        :ftp => {
          :port    => 21,
          :passive => false,
          :filters => ['/'], # dirs
        },
        :amzn_s3 => {
          :filters => [''], # prefixes
        },
        :goog_cs => {
          :filters => [''], # prefixes
        },
        :goog_doc => {
          :filters => [''], # prefixes
        },
        :rax_cf => {
          :endpoint => :us,
          :region   => :dfw,
          :filters  => [''], # prefixes
        },
      }
    end
    
    attr_reader :config
    attr_reader :running
    
    def initialize(eternal = false, opts = {})
      @eternal = eternal
      
      @logger = opts[:logger] || Logger.new(nil)
      
      @config = OpenStruct.new(self.class.config_defaults)
      
      @running = false
      @threads = {}
    end
    
    def configure
      yield @config
      
      @logger.level = Logger.const_get(@config.log_level)
      
      Redis.current = Redis::Namespace.new(@config.redis_ns_ryespy,
        :redis => Redis.connect(:url => @config.redis_url)
      )
      
      @logger.debug { "Configured #{@config.to_s}" }
    end
    
    def notifiers
      unless @notifiers
        @notifiers = []
        @config.notifiers[:sidekiq].each do |notifier_url|
          @notifiers << Notifier::Sidekiq.new(
            :url       => notifier_url,
            :namespace => @config.redis_ns_notifiers,
            :logger    => @logger
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
      require_relative "listener/#{@config.listener}"
    end
    
    def cleanup
    end
    
    def refresh_loop
      while @running do
        begin
          check_all
        rescue StandardError => e
          @logger.error { e.to_s }
          @logger.error { e.backtrace.to_s } #REMOVE!
          
          raise if @config.log_level == :DEBUG
        end
        
        if !@eternal
          stop
          
          break
        end
        
        @logger.debug { "Snoring for #{@config.polling_interval} s" }
        
        sleep @config.polling_interval # sleep awhile (snore)
      end
    end
    
    def check_all
      listener_class_map = {
        :imap    => :IMAP,
        :ftp     => :FTP,
        :amzn_s3 => :AmznS3,
        :goog_cs => :GoogCS,
        :goog_doc => :GoogDoc,
        :rax_cf  => :RaxCF,
      }
      
      listener_config = @config[@config.listener].merge({
        :notifiers => notifiers,
        :logger    => @logger,
      })
      
      listener_class = Listener.const_get(listener_class_map[@config.listener])
      
      listener_class.new(listener_config) do |listener|
        listener_config[:filters].each { |f| listener.check(f) }
      end
    end
    
  end
end
