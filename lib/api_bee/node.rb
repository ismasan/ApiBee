module ApiBee
  
  class Node
    
    def self.simbolized(hash)
      hash.inject({}) do |options, (key, value)|
        options[(key.to_sym rescue key) || key] = value
        options
      end
    end
    
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
    
    def [](attribute_name)
      if respond_to?(attribute_name)
        send attribute_name
      elsif value = @attributes[attribute_name]
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
    
    class Single < Node

    end

    class List < Node
      
      DEFAULT_PER_PAGE = 100
      
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
      
      def each_with_index(&block)
        __entries.each_with_index(&block)
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