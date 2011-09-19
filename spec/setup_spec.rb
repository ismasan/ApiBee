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
      end
      
    end
    
    it 'shoud instantiate adapter with options' do
      api = ApiBee.setup(CustomAdapter, :one => 1)
      api.adapter.should be_kind_of(CustomAdapter)
      api.adapter.opts.should == {:one => 1}
    end
    
  end
end