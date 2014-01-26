require_relative '../../helper'

require_relative '../../../lib/ryespy/notifier/sidekiq'


describe Ryespy::Notifier::Sidekiq do
  
  describe "#notify" do
    before do
      @sidekiq = Ryespy::Notifier::Sidekiq.new(
        :namespace => Ryespy::Test::Redis::namespace
      )
      
      @redis = @sidekiq.instance_variable_get(:@redis)
    end
    
    after do
      @sidekiq.close
      
      Ryespy::Test::Redis::flush_namespace(@redis)
    end
    
    it "writes to queues set" do
      @sidekiq.notify(nil, nil)
      
      @redis.smembers('queues').must_equal ['ryespy']
    end
    
    it "writes to queue list" do
      SecureRandom.stubs(:hex).returns('9c964160d25fdf24c6549e6d')
      
      @sidekiq.notify('PlanetClass', { :brain => 'marvin' })
      
      @redis.lrange('queue:ryespy', 0, -1).must_equal([{
        'class' => 'PlanetClass',
        'args'  => { 'brain' => 'marvin' },
        'queue' => 'ryespy',
        'retry' => true,
        'jid'   => '9c964160d25fdf24c6549e6d',
      }.to_json])
    end
  end
  
end
