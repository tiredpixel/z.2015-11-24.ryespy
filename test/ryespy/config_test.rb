require 'minitest/autorun'

require_relative '../../lib/ryespy'
require_relative '../../lib/ryespy/config'


describe Ryespy::Config do
  
  describe "default" do
    before do
      @config = Ryespy::Config.new
    end
    
    it "sets log_level to INFO" do
      @config.log_level.must_equal 'INFO'
    end
    
    it "sets polling_interval to 60" do
      @config.polling_interval.must_equal 60
    end
    
    it "sets redis_ns_ryespy to ryespy:" do
      @config.redis_ns_ryespy.must_equal 'ryespy:'
    end
  end
  
  describe "configure block" do
    before do
      Ryespy.configure do |c|
        c.log_level        = 'ERROR'
        c.listener         = 'imap'
        c.polling_interval = 13
        c.redis_url        = 'redis://127.0.0.1:6379/1'
        c.redis_ns_ryespy  = 'WithMyLittleEye!'
      end
      
      @config = Ryespy.config
    end
    
    it "configures log_level" do
      @config.log_level.must_equal 'ERROR'
    end
    
    it "configures listener" do
      @config.listener.must_equal 'imap'
    end
    
    it "configures polling_interval" do
      @config.polling_interval.must_equal 13
    end
    
    it "configures redis_url" do
      @config.redis_url.must_equal 'redis://127.0.0.1:6379/1'
    end
    
    it "configures redis_ns_ryespy" do
      @config.redis_ns_ryespy.must_equal 'WithMyLittleEye!'
    end
  end
  
  describe "#to_s" do
    before do
      @config = Ryespy::Config.new
    end
    
    it "stringifies hash of config" do
      @config.to_s.must_equal '{:log_level=>"INFO", :listener=>nil, :polling_interval=>60, :redis_url=>nil, :redis_ns_ryespy=>"ryespy:", :notifiers=>{:sidekiq=>[]}}'
    end
  end
  
end
