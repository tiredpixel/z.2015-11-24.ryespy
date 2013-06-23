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
  end
  
  describe "configure block" do
    before do
      Ryespy.configure do |c|
        c.log_level = 'ERROR'
        c.polling_interval = 13
      end
      
      @config = Ryespy.config
    end
    
    it "configures log_level" do
      @config.log_level.must_equal 'ERROR'
    end
    
    it "configures polling_interval" do
      @config.polling_interval.must_equal 13
    end
  end
  
  describe "#to_s" do
    before do
      @config = Ryespy::Config.new
    end
    
    it "stringifies hash of config" do
      @config.to_s.must_equal '{:log_level=>"INFO", :polling_interval=>60}'
    end
  end
  
end
