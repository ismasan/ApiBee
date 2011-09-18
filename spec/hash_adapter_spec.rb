require 'spec_helper'
require 'api_bee/adapters/hash'

describe ApiBee::Adapters::Hash do
  
  before do
    @data = {
      # Collections
      :collections        => [
        {
          :title          => 'Catalog',
          :id             => 'catalog',
          :products       => {
            :total_entries    => 4,
            :current_page     => 1,
            :per_page         => 2,
            :href             => '/products',
            :items            => [
              {
                :id           => 'foo-1',
                :href         => '/products/foo-1'
              },
              {
                :id           => 'foo-2',
                :title        => 'Foo 2',
                :href         => '/products/foo-2'
              }
            ]
          }
        }
      ]
    }
    
    @adapter        = ApiBee::Adapters::Hash.new(@data)
  end
  
  context 'accessing single nodes' do
    
    before do
      @collection     = @adapter.get('/collections/catalog')
    end
    
    it 'should find node by :id' do
      @collection[:title].should == 'Catalog'
      @collection[:id].should == 'catalog'
    end
  end
  
  context 'accessing node collections' do
    
    before do
      @list = @adapter.get('/collections/catalog/products/items')
    end
    
    it 'should return array' do
      @list.size.should == 2
      @list[0][:id].should == 'foo-1'
    end
  end
  
end