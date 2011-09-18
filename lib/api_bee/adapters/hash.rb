module ApiBee
  
  module Adapters
    
    class Hash
      
      attr_reader :data
      
      def initialize(*args)
        @data = args.last
      end
      
      def get(href)
        segments = parse_href(href)
        found = segments.inject(data) do |mem,i|
          case mem
          when ::Hash
            mem[i.to_sym]
          when ::Array
            if mem[0].kind_of?(::Hash)
              mem.find {|e| e[:id] == i}
            else
              mem
            end
          else
            mem
          end
        end
        found
      end
      
      protected
      
      def parse_href(href)
        href.gsub(/^\//, '').split('/')
      end
    end
    
  end
  
end