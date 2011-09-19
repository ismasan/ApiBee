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
          :foos           => [1,2,3,4],
          :products       => {
            :total_entries    => 4,
            :current_page     => 1,
            :per_page         => 2,
            :href             => '/products',
            :entries            => [
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
    
    it 'should find entries in paginated collections' do
      product = @adapter.get('/collections/catalog/products/foo-2')
      product[:title].should == 'Foo 2'
    end
    
    it 'should paginate paginated collections' do
      products = @adapter.get('/collections/catalog/products', :page => 2, :per_page => 1)
      products[:entries].size.should == 1
      products[:entries][0][:title].should == 'Foo 2'
    end
  end
  
  context 'accessing node collections' do
    
    before do
      @list = @adapter.get('/collections/catalog/foos')
    end
    
    it 'should return array' do
      @list.size.should == 4
      @list.should == [1,2,3,4]
    end
  end
  
end