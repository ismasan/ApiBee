module ApiBee
  
  # == API response objects
  #
  # A node wraps Hash data returned by adapter.get(path)
  # It inspects the returned data and tries to add lazy-loading of missing attributes (provided there is an :href attribute)
  # and pagination (see Node::List)
  #
  class Node
    
    def self.simbolized(hash)
      hash.inject({}) do |options, (key, value)|
        options[(key.to_sym rescue key) || key] = value
        options
      end
    end
    
    # Factory. Inspect passed attribute hash for pagination fields and reurns one of Node::List for paginated node lists
    # or Node::Single for single nodes
    # A node (list or single) may contain nested lists or single nodes. This is handled transparently by calling Node.resolve
    # when accessing nested attributes of a node.
    #
    # Example:
    #
    #   node = Node.resolve(an_adapter, config_object, {:total_entries => 10, :href => '/products', :entries => [...]})
    #   # node is a Node::List because is has pagination fields
    #
    #   node = Node.resolve(an_adapter, config_object, {:name => 'Ismael', :bday => '11/29/77'})
    #   # node is a Node::Single because it doesn't represent a paginated list
    #
    def self.resolve(adapter, config, attrs, href = nil)
      attrs = simbolized(attrs)
      keys = attrs.keys.map{|k| k.to_sym}
      if keys.include?(config.total_entries_property_name) && keys.include?(config.uri_property_name.to_sym) # is a paginator
        List.new adapter, config, attrs, href
      else
        Single.new adapter, config, attrs, href
      end
    end
    
    attr_reader :adapter
    
    def initialize(adapter, config, attrs, href)
      @adapter = adapter
      @config = config
      @attributes = {}
      @href = href
      update_attributes attrs
    end
    
    def to_data
      @attributes
    end
    
    # Lazy loading attribute accessor.
    # Attempts to look for an attribute in this node's present attributes
    # If the attribute is missing and the node has a :href attribute pointing to more data for this resource
    # it will delegate to the adapter for more data, update it's attributes and return the found value, if any
    #
    # Example:
    #
    #   data = {
    #     :href => '/products/6',
    #     :title => 'Ipod'
    #   }
    #
    #   node = Node.resolve(adapter, config, data)
    #
    #   node[:title] # => 'Ipod'. 
    #
    #   node[:price] # new request to /products/6
    #
    def [](attribute_name)
      if value = @attributes[attribute_name]
        resolve_values_to_nodes value
      elsif has_more? # check whether there's more info in API
        load_more!
        self[attribute_name] # recurse once
      else
        nil
      end
    end
    
    protected
    
    def update_attributes(attrs)
      @attributes.merge!(attrs)
    end
    
    def resolve_values_to_nodes(value)
      case value
      when ::Hash
        Node.resolve @adapter, @config, value
      when ::Array
        value.map {|v| resolve_values_to_nodes(v)} # recurse
      else
        value
      end
    end
    
    def has_more?
      !@complete && @attributes[@config.uri_property_name]
    end
    
    def load_more!
      more_data = @adapter.get(@attributes[@config.uri_property_name])
      update_attributes Node.simbolized(more_data) if more_data
      @complete = true
    end
    
    # == Single node
    #
    # Resolved when initial data hash doesn't include pagination attributes
    #
    class Single < Node

    end
    
    # == Paginated node list
    #
    # Resolved by Node.resolve when initial data hash contains pagination attributes :total_entries, :href and :entries
    # Note that these are the default values for those fields and they can be configured per-API via the passed config object.
    #
    # A Node::List exposes methods useful for paginating a list of nodes.
    #
    # Example:
    #
    #   data = {
    #     :total_entries => 10,
    #     :href => '/products',
    #     :page => 1,
    #     :per_page => 20,
    #     :entries => [
    #        {
    #          :title => 'Ipod'
    #        },
    #        {
    #          :title => 'Ipad'
    #        },
    #        ...
    #      ]
    #   }
    #
    #   list = Node.resolve(adapter, config, data)
    #   list.current_page # => 1
    #   list.has_next_page? # => true
    #   list.next_page # => 2
    #   list.size # => 20
    #   list.each ... # iterate current page
    #   list.first #=> an instance of Node::Single
    #
    class List < Node
      
      include Enumerable
      
      DEFAULT_PER_PAGE = 100
      
      # Get one resource from this list
      # Delegates to adapter.get_one(href, id) and resolves result.
      #
      def get_one(id)
        data = @adapter.get_one(@href, id)
        data.nil? ? nil : Node.resolve(@adapter, @config, data, @href)
      end
      
      def total_entries
        @attributes[:total_entries].to_i
      end
      
      def size
        __entries.size
      end
      
      def current_page
        (@attributes[:page] || 1).to_i
      end
      
      def per_page
        (@attributes[:per_page] || DEFAULT_PER_PAGE).to_i
      end
      
      def total_pages
        div = (total_entries.to_f / per_page.to_f).ceil
        div < 1 ? 1 : div
      end
      
      def next_page
        current_page + 1
      end
      
      def prev_page
        current_page - 1
      end
      
      def pages
        (1..total_pages).to_a
      end
      
      def has_next_page?
        next_page <= total_pages
      end
      
      def has_prev_page?
        current_page > 1
      end
      
      def first
        __entries.first
      end
      
      def last
        __entries.last
      end
      
      def each(&block)
        __entries.each(&block)
      end
      
      def paginate(options = {})
        data = @adapter.get(@attributes[@config.uri_property_name], options)
        Node.resolve @adapter, @config, data, @href
      end
      
      protected
      
      def __entries
        @entries ||= (self[@config.entries_property_name] || [])
      end

    end
    
  end
  
end