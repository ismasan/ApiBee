require 'ostruct'
module ApiBee
  
  class << ApiBee
    
    # Setup and instantiates a new API proxy (ApiBee::Proxy)
    # by wrapping a bundled or custom API adapter and passing optional arguments
    #
    # When a hash is passed as the adapter class, it will look for that class file in 
    # the bundled adapters directory:
    #
    #    ApiBee.setup(:hash, {})
    #
    # Looks for ApiBee::Adapters::Hash in lib/api_bee/adapters
    #
    # You can pass a custom adapter class
    #
    # Example:
    #
    #   class MyAdapter
    #     def initialize(api_key)
    #      @url = 'http://myservice.com'
    #     end
    #
    #     def get(path, options = {})
    #       # Fetch data from your service here
    #     end
    #   end
    #
    #   api = ApiBee.setup(MyAdapter, 'MY_API_KEY')
    #
    # That gives you an instance of ApiBee::Proxy wrapping an instance of your MyAdapter initialized with your key.
    #
    def setup(adapter_klass, *args)
      
      adapter = if adapter_klass.is_a?(::Symbol)
        require File.join('api_bee', 'adapters', adapter_klass.to_s)
        klass = adapter_klass.to_s.gsub(/(^.{1})/){$1.upcase}
        Adapters.const_get(klass).new(*args)
      else
        adapter_klass.new *args
      end

      raise NoMethodError, "Adapter must implement #get(path, *args) method" unless adapter.respond_to?(:get)
      
      config = new_config
      yield config if block_given?
      Proxy.new adapter, config
    end
    
    # new config object with defaults
    def new_config
      Config.new(
        # This field is expected in API responses
        # and should point to an individual resource with more data
        :uri_property_name            => :href,
        # Total number of entries
        # Used to paginate lists
        :total_entries_property_name  => :total_entries,
        # Name of array property
        # that contains cureent page's entries
        :entries_property_name        => :entries
      )
    end
    
    class Config < OpenStruct
      
      # Delegate method calls to your wrapped adapter
      #
      # Example:
      #
      #   api = ApiBee.setup(TwitterAdapter) do |config|
      #     config.expose :post_message, :delete_message
      #   end
      #
      # Now calls to api.post_message and api.delete_message will be delegated to an instance of TwitterAdapter
      #
      def expose(*fields)
        self.adapter_delegators = fields
      end
      
    end
    
  end
  
  module Adapters
    
  end
  
end

require 'api_bee/proxy'
require 'api_bee/node'
