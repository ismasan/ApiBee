require 'ostruct'
module ApiBee
  
  class << ApiBee
    attr_reader :config
    
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
      OpenStruct.new(
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
    
  end
  
  module Adapters
    
  end
  
end

require 'api_bee/proxy'
require 'api_bee/node'
