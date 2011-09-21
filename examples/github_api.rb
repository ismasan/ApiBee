$LOAD_PATH.unshift '../lib'
require 'api_bee'
#require 'net/http'
require 'net/https'
require 'uri'
require 'json'

class GithubAdapter
  
  def initialize
    ApiBee.config.uri_property_name = :url
    @url = URI.parse('https://api.github.com')
    @http = Net::HTTP.new(@url.host, @url.port)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  
  def get(path, options = {})
    per_page = (options[:per_page] || 20).to_i
    page = (options[:page] || 1).to_i
    
    q = options.map{|k,v| "#{k}=#{v}"}.join('&')
    
    fullpath = "#{path}?#{q}"
    
    request = Net::HTTP::Get.new(fullpath)
    response = @http.request(request)
    
    if response.kind_of?(Net::HTTPOK)
      results = JSON.parse response.body
      if results.is_a?(Array)
        # decorate returned array so it complies with APiBee's pagination params
        results = {
          :entries => results,
          :page => page,
          :per_page => per_page,
          :url => path
        }
        # Extract last page number and entries count. Github uses a 'Link' header
        if link = response["link"]
          last_page = extract_last_page(link) || page # if no 'last' link, we're on the last page
          results.update(
            :total_entries => last_page.to_i * per_page
          )
        end
      else
        results
      end
      
      results
    else
      nil
    end
    
  end
  
  def find_one(href, id)
    get id
  end
  
  protected
  
  def extract_last_page(link)
    aa = link.split('<https')
    last_link = aa.find{|e| e=~ /rel="last"/}
    last_link.to_s =~ /\?page=(\d+)/
    $1
  end
  
end

## Instantiate your wrapped API

api = ApiBee.setup(GithubAdapter)

repos = api.get('/users/ismasan/repos')

def show(data, c)
  puts "+++++++++++++++ Page #{data.current_page} of #{data.total_pages} (#{data.total_entries} entries). #{data.size} now. ++++++++"
  puts
  data.each do |pp|
    puts "#{c}.- #{pp[:id]}: #{pp[:name]}. Forks: #{pp[:forks]}. URL: #{pp[:url]}"
    c += 1
  end
  puts
  p [:next, data.next_page, data.total_entries]
  if data.has_next_page? # recurse
    show data.paginate(:page => data.next_page, :per_page => 20), c
  end
end

## Auto paginate over all the repos

show repos, 1


puts "First created at is: #{repos.first[:created_at]}"

# Fetch a single node 
one = repos.find_one('https://api.github.com/repos/ismasan/websockets_examples')

# one[:owner][:public_repos] will trigger a new request to the resource URL because that property is not available in the excerpt
#
puts "An owner is #{one[:owner][:login]}, who has #{one[:owner][:public_repos]} public repos"