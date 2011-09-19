$LOAD_PATH.unshift '../lib'
require 'yaml'
require 'api_bee'

api = ApiBee.setup(:hash, YAML.load_file('./catalog.yml'))

collections = api.get('/collections')

#p collections

p collections.current_page
# p collections.size

collection = api.get('/collections/c1')

p collection[:title]
p collection[:id]

products = collection[:products]

puts "First page"

products.each do |p|
  p p[:title]
end

puts "Second page"

products.paginate(:page => products.next_page, :per_page => 2).each do |p|
  p p[:title]
end