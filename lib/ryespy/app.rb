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
          :port    => 21,
          :passive => false,
          :dirs    => ['/'],
        },
        :amzn_s3 => {
          :prefixes => [''],
        },
        :goog_cs => {
          :prefixes => [''],
        },
        :rax_cf => {
          :endpoint => :us,
          :region   => :dfw,
          :prefixes => [''],
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
        :port      => @config.ftp[:port],
        :passive   => @config.ftp[:passive],
        :username  => @config.ftp[:username],
        :password  => @config.ftp[:password],
        :notifiers => notifiers,
        :logger    => @logger,
      ) do |listener|
        @config.ftp[:dirs].each { |d| listener.check(d) }
      end
    end
    
    def check_all_amzn_s3
      Listener::AmznS3.new(
        :access_key => @config.amzn_s3[:access_key],
        :secret_key => @config.amzn_s3[:secret_key],
        :bucket     => @config.amzn_s3[:bucket],
        :notifiers  => notifiers,
        :logger     => @logger,
      ) do |listener|
        @config.amzn_s3[:prefixes].each { |p| listener.check(p) }
      end
    end
    
    def check_all_goog_cs
      Listener::GoogCS.new(
        :access_key => @config.goog_cs[:access_key],
        :secret_key => @config.goog_cs[:secret_key],
        :bucket     => @config.goog_cs[:bucket],
        :notifiers  => notifiers,
        :logger     => @logger,
      ) do |listener|
        @config.goog_cs[:prefixes].each { |p| listener.check(p) }
      end
    end
    
    def check_all_rax_cf
      Listener::RaxCF.new(
        :endpoint  => @config.rax_cf[:endpoint],
        :region    => @config.rax_cf[:region],
        :username  => @config.rax_cf[:username],
        :api_key   => @config.rax_cf[:api_key],
        :container => @config.rax_cf[:container],
        :notifiers => notifiers,
        :logger    => @logger,
      ) do |listener|
        @config.rax_cf[:prefixes].each { |p| listener.check(p) }
      end
    end
    
  end
end
