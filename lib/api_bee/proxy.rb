module ApiBee
  
  class Proxy
    
    attr_reader :adapter
    
    def initialize(adapter)
      @adapter = adapter
    end
    
    def get(href)
      Node.resolve @adapter, :href => href
    end
    
  end
  
end