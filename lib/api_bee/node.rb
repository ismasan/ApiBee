module ApiBee
  
  class Node
    
    def self.resolve(adapter, attrs)
      keys = attrs.keys.map{|k| k.to_sym}
      if keys.include?(:total_entries) && keys.include?(:href) # is a paginator
        List.new adapter, attrs
      else
        Single.new adapter, attrs
      end
    end
    
    attr_reader :adapter
    
    def initialize(adapter, attrs)
      @adapter = adapter
      @attributes = {}
      update_attributes attrs
    end
    
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
        Node.resolve @adapter, value
      when ::Array
        value.map {|v| resolve_values_to_nodes(v)} # recurse
      else
        value
      end
    end
    
    def has_more?
      !@complete && @attributes[:href]
    end
    
    def load_more!
      more_data = @adapter.get(@attributes[:href])
      update_attributes more_data if more_data
      @complete = true
    end
    
    class Single < Node

    end

    class List < Node
      
      DEFAULT_PER_PAGE = 100
      
      def total_entries
        @attributes[:total_entries].to_i
      end
      
      def size
        entries.size
      end
      
      def current_page
        (@attributes[:current_page] || 1).to_i
      end
      
      def per_page
        (@attributes[:per_page] || DEFAULT_PER_PAGE).to_i
      end
      
      def total_pages
        div = total_entries / per_page
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
        entries.first
      end
      
      def last
        entries.last
      end
      
      def each(&block)
        entries.each(&block)
      end
      
      def each_with_index(&block)
        entries.each_with_index(&block)
      end
      
      def paginate(options = {})
        data = @adapter.get(@attributes[:href], options)
        Node.resolve @adapter, data
      end
      
      protected
      
      def entries
        @entries ||= (self[:entries] || [])
      end

    end
    
  end
  
end