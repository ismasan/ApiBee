$LOAD_PATH.unshift '../lib'
require 'yaml'
require 'api_bee'

require 'api_bee/adapters/hash'

class Product
  def initialize(node)
    @node = node
  end
  
  def title
    @node[:title]
  end
  
  def [](key)
    @node[key.to_sym]
  end
end

class Collection < Product
  def collection_title
    [title, @node[:id]].join('_')
  end
end

class Category < Product
  def name
    @node[:name]
  end
end

class Adapter < ApiBee::Adapters::Hash
  
  def wrap(node, name)
    puts "NAME is #{name}"
    case name
    when /products/
      Product.new node
    when /collections/
      Collection.new node
    when /categor/
      Category.new node
    else
      node
    end
  end
end

api = ApiBee.setup(Adapter, YAML.load_file(File.dirname(__FILE__)+'/catalog.yml'))

collections = api.get('/collections')
p collections.first.class.name

collections.each do |c|
  puts c.collection_title
end

#p collections

p collections.current_page
# p collections.size

collection = api.get('/collections/c1')

p collection[:title]
p collection[:id]

products = collection[:products]

p products.first.class.name

puts "First page"

products.each do |p|
  p p.title
  p p[:category].name
end

puts "Second page"

products.paginate(:page => products.next_page, :per_page => 2).each do |p|
  p p[:title]
end