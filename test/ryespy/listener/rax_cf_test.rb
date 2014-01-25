require_relative '../../helper'

require_relative '../../../lib/ryespy/listener/rax_cf'


describe Ryespy::Listener::RaxCF do
  
  before do
    etag = 'dvYAPmJPy8nyqtR8hqqPYIagWEDuZ9FN'
    
    @files = [
      stub(:content_type => 'application/directory', :key => 'host/', :etag => etag),
      stub(:content_type => 'text/plain', :key => 'host/bread.txt', :etag => etag),
      stub(:content_type => 'text/plain', :key => 'host/wine.txt', :etag => etag),
      stub(:content_type => 'application/directory', :key => 'h/', :etag => etag),
      stub(:content_type => 'text/plain', :key => 'h/host_README.txt', :etag => etag),
      stub(:content_type => 'application/directory', :key => 'cross/', :etag => etag),
      stub(:content_type => 'text/plain', :key => 'cross/cross.txt', :etag => etag),
    ]
    
    @files_no_dirs = @files.select { |f| f.content_type != 'application/directory' }
    
    @fog_storage = stub
    
    @fog_storage_directories = stub
    
    @fog_storage_directories.stubs(:get).with('tmtiscnoa', {
      :prefix => 'host/'
    }).returns(stub(:files => @files.select { |f| f.key =~ /^host\// }))
    @fog_storage_directories.stubs(:get).with('tmtiscnoa', {
      :prefix => 'h'
    }).returns(stub(:files => @files.select { |f| f.key =~ /^h/ }))
    @fog_storage_directories.stubs(:get).with('tmtiscnoa', {
      :prefix => 'cross/'
    }).returns(stub(:files => @files.select { |f| f.key =~ /^cross\// }))
    @fog_storage_directories.stubs(:get).with('tmtiscnoa', {
      :prefix => ''
    }).returns(stub(:files => @files))
    
    @fog_storage.stubs(:directories).returns(@fog_storage_directories)
    
    Fog::Storage.stubs(:new).with({
      :provider           => 'Rackspace',
      :rackspace_auth_url => 'https://lon.identity.api.rackspacecloud.com/v2.0',
      :rackspace_region   => :lon,
      :rackspace_username => 'van.helsing',
      :rackspace_api_key  => 'M.D., D.Ph., D.Litt., etc.',
    }).returns(@fog_storage)
  end
  
  describe "#check" do
    before do
      Ryespy::Test::Redis::setup
      
      @notifier = mock()
      
      @rax_cf = Ryespy::Listener::RaxCF.new(
        :endpoint  => 'uk',
        :region    => 'lon',
        :username  => 'van.helsing',
        :api_key   => 'M.D., D.Ph., D.Litt., etc.',
        :container => 'tmtiscnoa',
        :notifiers => [@notifier],
      )
      
      @redis = @rax_cf.instance_variable_get(:@redis)
    end
    
    after do
      @rax_cf.close
      
      Ryespy::Test::Redis::flush_namespace(@redis)
    end
    
    it "notifies when new files prefix *" do
      @files_no_dirs.each do |file|
        @notifier.expects(:notify).with('RyespyRaxCFJob', [file.key]).once
      end
      
      @rax_cf.check('')
    end
    
    it "notifies when new files prefix cross/" do
      @files_no_dirs.select { |f| f.key =~ /^cross\// }.each do |file|
        @notifier.expects(:notify).with('RyespyRaxCFJob', [file.key]).once
      end
      
      @rax_cf.check('cross/')
    end
    
    it "notifies when new files prefix h" do
      @files_no_dirs.select { |f| f.key =~ /^h/ }.each do |file|
        @notifier.expects(:notify).with('RyespyRaxCFJob', [file.key]).once
      end
      
      @rax_cf.check('h')
    end
    
    it "doesn't notify when no new files" do
      @notifier.expects(:notify).times(2)
      
      @rax_cf.check('host/')
      
      @notifier.expects(:notify).never
      
      @rax_cf.check('host/')
    end
    
    it "doesn't notify when no new files prefix subset" do
      @notifier.expects(:notify).times(3)
      
      @rax_cf.check('h')
      
      @notifier.expects(:notify).never
      
      @rax_cf.check('host/')
    end
    
    it "notifies when new files prefix distinct" do
      @notifier.expects(:notify).times(3)
      
      @rax_cf.check('h')
      
      @notifier.expects(:notify).times(1)
      
      @rax_cf.check('cross/')
    end
    
    it "notifies when changed etag" do
      @notifier.expects(:notify).times(2)
      
      @rax_cf.check('host/')
      
      @files[1].stubs(:etag).returns(-2303600400)
      
      @notifier.expects(:notify).with('RyespyRaxCFJob', ['host/bread.txt']).once
      
      @rax_cf.check('host/')
    end
  end
  
end
