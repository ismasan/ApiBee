require 'spec_helper'

describe 'ApiBee.setup' do
  
  describe 'with bundled adapter' do
    
    it 'should return a proxy to instantiated adapter' do
      api = ApiBee.setup(:hash, {})
      api.adapter.should be_kind_of(ApiBee::Adapters::Hash)
    end
  end
  
  describe 'with custom adapter class' do
    before do
      
      class CustomAdapter
        attr_reader :opts
        def initialize(opts)
          @opts = opts
        end
        
        def get(path, *args);end
      end
      
    end
    
    it 'shoud instantiate adapter with options' do
      api = ApiBee.setup(CustomAdapter, :one => 1)
      api.adapter.should be_kind_of(CustomAdapter)
      api.adapter.opts.should == {:one => 1}
    end
    
  end
  
  describe 'with adapter without #get method' do
    it 'should complain' do
      lambda {
        ApiBee.setup(String)
      }.should raise_error("Adapter must implement #get(path, *args) method")
    end
    
  end
  
  context 'configuration' do
    
    before do
      @api1 = ApiBee.setup(:hash, {
        :user => {
          :name => 'ismael 1',
          :href => '/users/ismael1'
        }
      })
      
      @api2 = ApiBee.setup(:hash, {
        :user => {
          :name => 'ismael 2',
          :url => '/users/ismael2'
        }
      }) do |config|
        config.uri_property_name = :url
      end
    end
    
    describe 'API config' do
      
      it 'should produce a config object with default values' do
        config = ApiBee.new_config
        config.uri_property_name.should == :href
        config.total_entries_property_name.should == :total_entries
        config.entries_property_name.should == :entries
      end
      
      it 'should have default :href configured' do
        user = @api1.get('/user')
        user[:name].should == 'ismael 1'
        @api1.adapter.should_receive(:get).with('/users/ismael1').and_return(:last_name => 'Celis')

        user[:last_name].should == 'Celis'
      end
      
      it 'should overwrite config for individual apis' do
        user1 = @api1.get('/user')
        user1[:name].should == 'ismael 1'
        @api1.adapter.should_receive(:get).with('/users/ismael1').and_return(:last_name => 'Celis 1')

        user1[:last_name].should == 'Celis 1'
        
        user2 = @api2.get('/user')
        user2[:name].should == 'ismael 2'
        @api2.adapter.should_receive(:get).with('/users/ismael2').and_return(:last_name => 'Celis 2')

        user2[:last_name].should == 'Celis 2'
      end

    end
    
    describe 'delegate to adapter' do
      
      before do
        
        adapter = Class.new(ApiBee::Adapters::Hash) do
          def fetch(*args)
            @data.fetch *args
          end
          
          def keys(*args)
            @data.keys *args
          end
        end
        
        @api = ApiBee.setup(adapter, {
          :a => {:name => 1},
          :b => {:name => 2}
        }) do |config|
          config.expose :fetch, :keys
        end
        
      end
      
      it 'should still work' do
        @api.get('/a').should == {:name => 1}
        @api.get('/b').should == {:name => 2}
      end
      
      it 'should delegate configured methods on to adapter' do
        @api.fetch(:a).should == {:name => 1}
        @api.fetch(:x, 'X').should == 'X'
        
        @api.keys.should == [:a, :b]
      end
      
    end
  end
  
end