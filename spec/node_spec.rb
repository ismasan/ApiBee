require 'spec_helper'

describe ApiBee do
  
  before do
    @data = {
      # Products
      :products         => {
        :href => '/products',
        :total_entries => 7,
        :entries => [
          {
            :title        => 'Foo 1',
            :id           => 'foo-1',
            :price        => 100,
            :description  => 'Foo 1 desc'
          },
          {
            :title        => 'Foo 2',
            :id           => 'foo-2',
            :price        => 200,
            :description  => 'Foo 2 desc'
          },
          {
            :title        => 'Foo 3',
            :id           => 'foo-3',
            :price        => 300,
            :description  => 'Foo 3 desc'
          },
          {
            :title        => 'Foo 4',
            :id           => 'foo-4',
            :price        => 400,
            :description  => 'Foo 4 desc'
          },
          {
            :title        => 'Foo 5',
            :id           => 'foo-5',
            :price        => 500,
            :description  => 'Foo 5 desc'
          },
          {
            :title        => 'Foo 6',
            :id           => 'foo-6',
            :price        => 600,
            :description  => 'Foo 6 desc'
          },
          {
            :title        => 'Foo 7',
            :id           => 'foo-7',
            :price        => 700,
            :description  => 'Foo 7 desc'
          }
        ]
      },
      # Collections
      :collections        => [
        {
          :title          => 'Catalog',
          :id             => 'catalog',
          :products       => {
            :href           => '/products',
            :total_entries    => 4,
            :page             => 1,
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
    
  end
  
  describe '.resolve' do
    
    before do
      @adapter = mock('Adapter')
      @config = ApiBee.new_config
    end
    
    it 'should resolve single nodes' do
      node = ApiBee::Node.resolve(@adapter, @config, {:title => 'Blah', :foo => [1,2,3]})
      node[:title].should == 'Blah'
      node.adapter.should == @adapter
      node.should be_kind_of(ApiBee::Node::Single)
    end
    
    it 'should symbolize hash keys' do
      node = ApiBee::Node.resolve(@adapter, @config, {
        'title' => 'Blah', 
        'total_entries' => 4, 
        'href' => '/products',
        'foos' => [1,2,3,4]
      })
      node.total_entries.should == 4
      node[:foos].should == [1,2,3,4]
      node.adapter.should == @adapter
      node.should be_kind_of(ApiBee::Node::List)
    end
    
    it 'should resolve paginated lists' do
      node = ApiBee::Node.resolve(@adapter, @config, {:title => 'Blah', :total_entries => 4, :href => '/products'})
      node.total_entries.should == 4
      node.adapter.should == @adapter
      node.should be_kind_of(ApiBee::Node::List)
    end
  end
  
  context 'lazy loading' do
    before do
      require 'api_bee/adapters/hash'
      @adapter = ApiBee::Adapters::Hash.new(@data)
      ApiBee::Adapters::Hash.should_receive(:new).with(@data).and_return @adapter
      @api = ApiBee.setup(:hash, @data)
    end
    
    it 'should return a Proxy' do
      @api.should be_kind_of(ApiBee::Proxy)
    end
    
    describe 'single nodes' do
      it 'should call adapter only when accessing needed attributes' do
        hash = @data[:collections].last
        @adapter.should_receive(:get).exactly(1).times.with('/collections/catalog', {}).and_return hash
        node = @api.get('/collections/catalog')
        node[:title].should == 'Catalog'
        node[:id].should == 'catalog'
      end
    end
    
    describe '#get_one' do
      
      before do
        @products = @api.get('/products', :page => 1, :per_page => 2)
      end
      
      it 'should delegate to adapter. It knows how to find individual resoruces' do
        @adapter.should_receive(:get_one).with('/products', 'foo-1')
        @products.get_one('foo-1')
      end
      
      it 'should return a Node::Single' do
        node = @products.get_one('foo-1')
        node.should be_kind_of(ApiBee::Node::Single)
        node[:title].should == 'Foo 1'
      end
      
      it 'should return nil if not found' do
        @products.get_one('foo-1000').should be_nil
      end
      
    end
    
  end
  
  context 'navigating data' do
    
    before do
      @api = ApiBee.setup(:hash, @data)
    end
    
    describe '#to_data' do
      it 'should return raw data' do
        d = @api.get('/collections/catalog').to_data
        d.should be_kind_of(::Hash)
        d.should == @data[:collections].first
      end
    end
    
    describe 'paginated root level lists' do
      
      before do
        @products = @api.get('/products', :page => 1, :per_page => 2)
      end
      
      it 'should have a paginator interface' do
        
        @products.total_entries.should == 7
        @products.size.should == 2
        @products.total_pages.should == 4
        @products.current_page.should == 1
        @products.pages.should == [1,2,3,4]
        @products.has_next_page?.should be_true
        @products.has_prev_page?.should be_false
      end
      
      it 'should paginate last page correctly' do
        last_page = @products.paginate(:per_page => 2, :page =>4)

        last_page.total_entries.should == 7
        last_page.size.should == 1
        last_page.total_pages.should == 4
        last_page.current_page.should == 4
        last_page.pages.should == [1,2,3,4]
        last_page.has_next_page?.should be_false
        last_page.has_prev_page?.should be_true
      end
    end
    
    describe 'paginated nested lists' do
      before do
        @collection = @api.get('/collections/catalog')
        @products = @collection[:products]
      end
      
      it 'should have a paginator interface' do
        @products.total_entries.should == 4
        @products.size.should == 2
        @products.total_pages.should == 2
        @products.current_page.should == 1
        @products.pages.should == [1,2]
        @products.has_next_page?.should be_true
        @products.has_prev_page?.should be_false
      end
      
      it 'should iterate the first page' do
        titles = []
        klasses = []
        @products.each {|p| titles << p[:title]}
        @products.each {|p| klasses << p.class}
        klasses.should == [ApiBee::Node::Single, ApiBee::Node::Single]
        titles.should == ['Foo 1', 'Foo 2']
        @products.first[:title].should == 'Foo 1'
        @products.last[:title].should == 'Foo 2'
      end
      
      it 'should implement #map' do
        @products.map {|p| p[:title]}.should == ['Foo 1', 'Foo 2']
      end
      
      it 'should implement #each_with_index' do
        idx = []
        titles = []
        @products.each_with_index {|p,i| idx << i; titles << p[:title]}
        
        idx.should == [0,1]
        titles.should == ['Foo 1', 'Foo 2']
      end
      
      it 'should navigate to the second page' do
        @products = @products.paginate(:page => 2, :per_page => 2)
        titles = []
        klasses = []
        @products.each {|p| titles << p[:title]}
        @products.each {|p| klasses << p.class}
        @products.current_page.should == 2
        @products.total_entries.should == 7
        @products.size.should == 2
        klasses.should == [ApiBee::Node::Single, ApiBee::Node::Single]
        titles.should == ['Foo 3', 'Foo 4']
        @products.first[:title].should == 'Foo 3'
        @products.last[:title].should == 'Foo 4'
      end
      
    end
    
  end
  
end