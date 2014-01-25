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
          :port      => 993,
          :ssl       => true,
          :mailboxes => ['INBOX'],
        },
        :ftp => {
          :passive => false,
          :dirs    => ['/'],
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
          send(:"check_all_#{@config.listener}")
        rescue StandardError => e
          @logger.error { e.to_s }
        end
        
        if !@eternal
          stop
          
          break
        end
        
        @logger.debug { "Snoring for #{@config.polling_interval} s" }
        
        sleep @config.polling_interval # sleep awhile (snore)
      end
    end
    
    def check_all_imap
      Listener::IMAP.new(
        :host      => @config.imap[:host],
        :port      => @config.imap[:port],
        :ssl       => @config.imap[:ssl],
        :username  => @config.imap[:username],
        :password  => @config.imap[:password],
        :notifiers => notifiers,
        :logger    => @logger,
      ) do |listener|
        @config.imap[:mailboxes].each { |m| listener.check(m) }
      end
    end
    
    def check_all_ftp
      Listener::FTP.new(
        :host      => @config.ftp[:host],
        :passive   => @config.ftp[:passive],
        :username  => @config.ftp[:username],
        :password  => @config.ftp[:password],
        :notifiers => notifiers,
        :logger    => @logger,
      ) do |listener|
        @config.ftp[:dirs].each { |d| listener.check(d) }
      end
    end
    
  end
end
