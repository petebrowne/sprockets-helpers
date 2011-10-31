module Sprockets
  module Helpers
    # `AssetPath` generates a full path for an asset
    # that exists in Sprockets environment.
    class AssetPath < FilePath
      #
      def initialize(asset, options = {})
        @options = {
          :body   => false,
          :digest => Helpers.digest,
          :prefix => Helpers.prefix
        }.merge options
        
        @source = @options[:digest] ? asset.digest_path : asset.logical_path
      end
      
      protected
      
      # Prepends the base path if the path is not
      # already an absolute path.
      def rewrite_base_path(path) # :nodoc:
        File.join @options[:prefix], path
      end
      
      # Rewrite the query string to inlcude body flag if necessary.
      def rewrite_query(path)
        options[:body] ? "#{path}?body=1" : path
      end
    end
  end
end
