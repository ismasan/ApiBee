module ApiBee
  
  class Proxy
    
    attr_reader :adapter
    
    def initialize(adapter, href = nil, opts = nil)
      @adapter = adapter
      @href = href
      @opts = opts
    end
    
    def get(href, opts = {})
      # Just delegate. No API calls at this point. We only load data when we need it.
      Proxy.new @adapter, href, opts
    end
    
    def [](key)
      _node[key]
    end
    
    def to_data
      _node.to_data
    end
    
    protected
    
    def method_missing(method_name, *args)
      if args.empty?
        _node[method_name]
      else
        @adapter.send(method_name, *args)
      end
    end
    
    def _node
      @node ||= (
        data = @adapter.get(@href, @opts)
        Node.resolve @adapter, data
      )
    end
    
  end
  
end