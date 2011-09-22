module ApiBee
  
  class Proxy
    
    attr_reader :adapter
    
    def initialize(adapter, config, href = nil, opts = nil)
      @adapter = adapter
      @config = config
      @href = href
      @opts = opts
    end
    
    def get(href, opts = {})
      # Just delegate. No API calls at this point. We only load data when we need it.
      Proxy.new @adapter, @config, href, opts
    end
    
    def [](key)
      _node[key]
    end
    
    def to_data
      _node.to_data
    end
    
    def paginate(*args)
      @list ||= Node::List.new(@adapter, @config, {@config.uri_property_name => @href}, @href)
      @list.paginate *args
    end
    
    def ==(other)
      _node.to_data
    end
    
    protected
    
    def method_missing(method_name, *args, &block)
      if _adapter_delegators.include?(method_name)
        @adapter.send(method_name, *args, &block)
      else
        _node.send(method_name, *args, &block)
      end
    end
    
    def _adapter_delegators
      @adapter_delegators ||= @config.adapter_delegators || []
    end
    
    def _node
      @node ||= (
        data = @adapter.get(@href, @opts)
        Node.resolve @adapter, @config, data, @href
      )
    end
    
  end
  
end