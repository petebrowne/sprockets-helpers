module Sprockets
  module Helpers
    # `FilePath` generates a full path for a regular file
    # in the output path. It's used by #asset_path to generate
    # paths when using asset tags like #javascript_include_tag,
    # #stylesheet_link_tag, and #image_tag
    class FilePath
      # The parsed URI from which to generate the full path to the asset.
      attr_reader :uri
      
      # The various options used when generating the path.
      attr_reader :options
      
      # The base directory the file would be found in
      attr_reader :dir
    
      #
      def initialize(uri, options = {})
        @uri     = uri
        @options = options
        @dir     = options[:dir].to_s
      end
      
      # Returns the full path to the asset, complete with
      # timestamp.
      def to_s
        rewrite_base_path
        rewrite_query
        uri.to_s
      end
      
      protected
      
      # Prepends the base path if the path is not
      # already an absolute path.
      def rewrite_base_path # :nodoc:
        if uri.path[0] != ?/
          prepend_path(File.join('/', dir))
        end
      end
      
      # Appends an asset timestamp based on the
      # modification time of the asset.
      def rewrite_query # :nodoc:
        if timestamp = mtime
          append_query(timestamp.to_i.to_s)
        end
      end
      
      # Returns the mtime for the given path (relative to
      # the output path). Returns nil if the file doesn't exist.
      def mtime # :nodoc:
        public_path = File.join(Helpers.public_path, uri.path)
        
        if File.exist?(public_path)
          File.mtime(public_path)
        else
          nil
        end
      end
      
      # Prepends the given path. If the path is absolute
      # An attempt to merge the URIs is made.
      def prepend_path(value)
        prefix_uri = URI.parse(value)
        uri.path   = File.join prefix_uri.path, uri.path
        
        if prefix_uri.absolute?
          @uri = prefix_uri.merge(uri)
        end
      end
      
      # Append the given query string to the URI
      # instead of clobbering it.
      def append_query(value) # :nodoc:
        if uri.query.nil? || uri.query.empty? 
          uri.query = value
        else
          uri.query << ('&' + value)
        end
      end
    end
  end
end
