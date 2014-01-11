require_relative '../../helper'

require_relative '../../../lib/ryespy/config'
require_relative '../../../lib/ryespy/notifier/sidekiq'


describe Ryespy::Notifier::Sidekiq do
  
  describe "#initialize" do
    before do
      @sidekiq = Ryespy::Notifier::Sidekiq.new
    end
  end
  
  describe "#close" do
    before do
      @sidekiq = Ryespy::Notifier::Sidekiq.new
    end
    
    it "closes redis connection" do
      @sidekiq.instance_variable_get(:@redis).expects(:quit)
      
      @sidekiq.close
    end
  end
  
  describe "#notify" do
    before do
      @redis = stub(
        :ping => nil
      )
      
      Redis.stubs(:connect).returns(@redis)
      
      @config = Ryespy::Config.new
      
      @config.instance_variable_set(:@redis_ns_notifiers, 'ryespy-test:da')
      
      @sidekiq = Ryespy::Notifier::Sidekiq.new(
        :namespace => @config.redis_ns_notifiers
      )
    end
    
    it "writes to redis set" do
      @redis.stubs(:rpush)
      
      @redis.expects(:sadd).with('ryespy-test:da:queues', 'ryespy')
      
      @sidekiq.notify('', {})
    end
    
    it "writes to redis list" do
      @redis.stubs(:sadd)
      
      SecureRandom.stubs(:hex).returns('JID')
      
      @redis.expects(:rpush).with('ryespy-test:da:queue:ryespy', {
        :class => 'PlanetClass',
        :args  => { :brain => 'marvin' },
        :queue => 'ryespy',
        :retry => true,
        :jid   => 'JID',
      }.to_json)
      
      @sidekiq.notify('PlanetClass', { :brain => 'marvin' })
    end
  end
  
end
