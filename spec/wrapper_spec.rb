require 'spec_helper'

describe ApiBee do
  
  before do
    
    class BookWrapper
      attr_accessor :node
      def initialize(node)
        @node = node
      end
      
      def title_and_isbn
        [@node[:title], @node[:isbn]].join ' '
      end
      
      def author
        @node[:author]
      end
      
      def genre
        @node[:genre]
      end
    end
    
    class AuthorWrapper < BookWrapper
      def name
        @node[:name]
      end
    end
    
    @adapter = Class.new do
      
      def get(*args)
        # will be mocked
      end
      
      def wrap(node, name)
        case name
        when /book/
          BookWrapper.new node
        when /author/
          AuthorWrapper.new node
        else
          node
        end
      end
    end
    
    @data = {
      :total_entries    => 5,
      :page             => 1,
      :per_page         => 2,
      :href             => '/books',
      :entries          => [
        {
          :title    => 'Heart of Darkness',
          :isbn     => 123,
          :author   => {
            :name => 'J Conrad'
          },
          :genre => {
            :name => 'fiction'
          }
        },
        {
          :title    => 'Rayuela',
          :isbn     => 124,
          :author   => {
            :name => 'Julio Cortazar'
          },
          :genre => {
            :name => 'fiction'
          }
        }
      ]
    }
    
    @adapter_instance = @adapter.new
    
    @adapter.stub!(:new).and_return @adapter_instance
    
    @adapter_instance.stub!(:get).with('/books', {}).and_return @data
    
    @adapter_instance.stub!(:get).with('/books/123', {}).and_return @data[:entries].first
    
    @api = ApiBee.setup(@adapter)
  end
  
  it 'should return a proxy' do
    @api.get('/books').should be_kind_of(ApiBee::Proxy)
  end
  
  context 'iterating' do
    it 'should wrap first level nodes' do
      @api.get('/books').map do |book|
        book.class
      end.should == [BookWrapper, BookWrapper]
    end
    
    it 'should initialize wrappers with node as argument' do
      @api.get('/books').map do |book|
        book.title_and_isbn
      end.should == ["Heart of Darkness 123", "Rayuela 124"]
    end
    
    it 'should wrap nested nodes' do
      @api.get('/books').map do |book|
        book.author.class
      end.should == [AuthorWrapper, AuthorWrapper]
    end
    
    it 'should initialize nested wrappers with node as argument' do
      @api.get('/books').map do |book|
        book.author.name
      end.should == ['J Conrad', 'Julio Cortazar']
    end
    
    it 'should NOT wrap nested nodes if no wrapper defined' do
      @api.get('/books').map do |book|
        book.genre.class
      end.should == [ApiBee::Node::Single, ApiBee::Node::Single]
    end
  end
  
  context 'accesing single nodes' do
    it 'should wrap them' do
      @api.get('/books/123').title_and_isbn.should == 'Heart of Darkness 123'
    end
  end
  
end