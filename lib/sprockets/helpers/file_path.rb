module Sprockets
  module Helpers
    # `FilePath` generates a full path for a regular file
    # in the output path. It's used by #asset_path to generate
    # paths when using asset tags like #javascript_include_tag,
    # #stylesheet_link_tag, and #image_tag
    class FilePath
      # The path from which to generate the full path to the asset.
      attr_reader :source
      
      # The various options used when generating the path.
      attr_reader :options
      
      # The base directory the file would be found in
      attr_reader :dir
    
      #
      def initialize(source, options = {})
        @source  = source.to_s
        @options = options
        @dir     = options[:dir].to_s
      end
      
      # Returns the full path to the asset, complete with
      # timestamp.
      def to_s
        path = rewrite_base_path(source)
        path = rewrite_query(path)
        path
      end
      
      protected
      
      # Prepends the base path if the path is not
      # already an absolute path.
      def rewrite_base_path(path) # :nodoc:
        if path !~ %r(^/)
          File.join('/', dir, path)
        else
          path
        end
      end
      
      # Appends an asset timestamp based on the
      # modification time of the asset.
      def rewrite_query(path) # :nodoc:
        if timestamp = mtime(path)
          "#{path}?#{timestamp.to_i}"
        else
          path
        end
      end
      
      # Returns the mtime for the given path (relative to
      # the output path). Returns nil if the file doesn't exist.
      def mtime(path) # :nodoc:
        public_path = File.join(Helpers.public_path, path)
        
        if File.exist?(public_path)
          File.mtime(public_path)
        else
          nil
        end
      end
    end
  end
end
