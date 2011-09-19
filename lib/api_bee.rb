require 'ostruct'
module ApiBee
  
  class << ApiBee
    attr_reader :config
    
    def setup(adapter_klass, *args)
      
      yield config if block_given?
      
      adapter = if adapter_klass.is_a?(::Symbol)
        require File.join('api_bee', 'adapters', adapter_klass.to_s)
        klass = adapter_klass.to_s.gsub(/(^.{1})/){$1.upcase}
        Adapters.const_get(klass).new(*args)
      else
        adapter_klass.new *args
      end

      raise NoMethodError, "Adapter must implement #get(path, *args) method" unless adapter.respond_to?(:get)
      Proxy.new adapter
    end
    
    def config
      @config ||= OpenStruct.new
    end
    
  end
  
  # Defaults
  self.config.uri_property_name = :href
  
  module Adapters
    
  end
  
end

require 'api_bee/proxy'
require 'api_bee/node'
