require 'logger'
require 'redis'


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
      
      Redis.current = Redis.connect(:url => @config.redis_url)
      
      @logger.debug { "Configured #{@config.to_s}" }
    end
    
    def notifiers
      unless @notifiers
        @notifiers = []
        
        @config.notifiers[:sidekiq].each do |notifier_url|
          @notifiers << Notifier::Sidekiq.new(
            :url                => notifier_url,
            :redis_ns_notifiers => @config.redis_ns_notifiers,
            :logger             => @logger
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
        begin
          case @config.listener.to_sym
          when :imap
            check_all_imap
          when :ftp
            check_all_ftp
          end
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
        :host            => @config.imap_host,
        :port            => @config.imap_port,
        :ssl             => @config.imap_ssl,
        :username        => @config.imap_username,
        :password        => @config.imap_password,
        :mailboxes       => @config.imap_mailboxes,
        :redis_ns_ryespy => @config.redis_ns_ryespy,
        :notifiers       => notifiers,
        :logger          => @logger,
      ) do |listener|
        listener.check_all
      end
    end
    
    def check_all_ftp
      Listener::FTP.new(
        :host            => @config.ftp_host,
        :passive         => @config.ftp_passive,
        :username        => @config.ftp_username,
        :password        => @config.ftp_password,
        :dirs            => @config.ftp_dirs,
        :redis_ns_ryespy => @config.redis_ns_ryespy,
        :notifiers       => notifiers,
        :logger          => @logger,
      ) do |listener|
        listener.check_all
      end
    end
    
  end
end
