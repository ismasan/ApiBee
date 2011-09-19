module ApiBee
  
  class Proxy
    
    attr_reader :adapter
    
    def initialize(adapter)
      @adapter = adapter
    end
    
    def get(href)
      Node.resolve @adapter, ApiBee.config.uri_property_name => href
    end
    
  end
  
end