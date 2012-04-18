module Sprockets
  module Helpers
    # `AssetPath` generates a full path for an asset
    # that exists in Sprockets environment.
    class ManifestPath < FilePath
      #
      def initialize(path, options = {})
        @options = {
          :body   => false,
          :prefix => Helpers.prefix
        }.merge options
        
        @source = path.to_s
      end
      
      protected
      
      # Prepends the base path if the path is not
      # already an absolute path.
      def rewrite_base_path(path) # :nodoc:
        prefix = if options[:prefix].respond_to? :call
          options[:prefix].call path
        else
          options[:prefix].to_s
        end

        File.join prefix, path
      end
      
      # Rewrite the query string to inlcude body flag if necessary.
      def rewrite_query(path)
        options[:body] ? "#{path}?body=1" : path
      end
    end
  end
end
