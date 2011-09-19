require 'spec_helper'

describe ApiBee do
  
  before do
    @data = {
      # Products
      :products         => {
        :href => '/products',
        :total_entries => 6,
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
    
  end
  
  describe '.resolve' do
    
    before do
      @adapter = mock('Adapter')
    end
    
    it 'should resolve single nodes' do
      node = ApiBee::Node.resolve(@adapter, {:title => 'Blah', :foo => [1,2,3]})
      node[:title].should == 'Blah'
      node.adapter.should == @adapter
      node.should be_kind_of(ApiBee::Node::Single)
    end
    
    it 'should resolve paginated lists' do
      node = ApiBee::Node.resolve(@adapter, {:title => 'Blah', :total_entries => 4, :href => '/products'})
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
        @adapter.should_receive(:get).exactly(1).times.with('/collections/catalog').and_return hash
        node = @api.get('/collections/catalog')
        node[:title].should == 'Catalog'
        node[:id].should == 'catalog'
      end
    end
    
    describe 'paginated lists' do
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
      
      it 'should navigate to the second page' do
        @products = @products.paginate(:page => 2, :per_page => 2)
        titles = []
        klasses = []
        @products.each {|p| titles << p[:title]}
        @products.each {|p| klasses << p.class}
        @products.current_page.should == 2
        @products.total_entries.should == 6
        @products.size.should == 2
        klasses.should == [ApiBee::Node::Single, ApiBee::Node::Single]
        titles.should == ['Foo 3', 'Foo 4']
        @products.first[:title].should == 'Foo 3'
        @products.last[:title].should == 'Foo 4'
      end
      
    end
    
  end
  
end