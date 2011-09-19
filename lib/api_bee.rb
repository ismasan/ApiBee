module ApiBee
  
  def self.setup(adapter_klass, *args)

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
  
  module Adapters
    
  end
  
end

require 'api_bee/proxy'
require 'api_bee/node'
