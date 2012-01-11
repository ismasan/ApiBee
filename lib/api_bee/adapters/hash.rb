module ApiBee
  
  module Adapters
    
    class Hash
      
      attr_reader :data
      
      def initialize(*args)
        @data = args.last
      end
      
      def get(href, opts = {})
        segments = parse_href(href)
        segments.inject(data) do |mem,i|
          case mem
          when ::Hash
            handle_hash_data mem, i, opts
          when ::Array
            handle_array_data mem, i
          else
            mem
          end
        end
      end
      
      def get_one(href, id)
        get("#{href}/#{id}")
      end
      
      protected
      
      def parse_href(href)
        href.gsub(/^\//, '').split('/')
      end
      
      def handle_hash_data(hash, key, opts = {})
        if is_paginated?(hash) # paginated collection
          handle_array_data hash[:entries], key
        else # /products. Might be a paginated list
          r = hash[key.to_sym]
          if opts.keys.include?(:page) && opts.keys.include?(:per_page) && r.kind_of?(::Hash) && is_paginated?(r)
            paginate(r, opts[:page], opts[:per_page])
          else
            r
          end
        end
      end
      
      def handle_array_data(array, key)
        if array[0].kind_of?(::Hash)
          array.find {|e| e[:id].to_s == key}
        else
          array
        end
      end
      
      def is_paginated?(hash)
        hash[:href] && hash[:total_entries]
      end
      
      def paginate(list, page, per_page)
        from = page * per_page - per_page
        to =  page * per_page
        list[:entries] = list[:entries].to_a[from...to]
        list[:page] = page
        list[:per_page] = per_page
        list
      end
      
    end
    
  end
  
end