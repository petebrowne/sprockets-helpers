require 'uri'

module Sprockets
  module Helpers
    # `AssetPath` generates a full path for an asset
    # that exists in Sprockets environment.
    class AssetPath < FilePath
      #
      def initialize(uri, asset, options = {})
        @uri     = uri
        @options = {
          :body   => false,
          :digest => Helpers.digest,
          :prefix => Helpers.prefix
        }.merge options
        
        @uri.path = @options[:digest] ? asset.digest_path : asset.logical_path
      end
      
      protected
      
      # Prepends the assets prefix
      def rewrite_base_path # :nodoc:
        prefix = if options[:prefix].respond_to? :call
          options[:prefix].call uri.path
        else
          options[:prefix].to_s
        end
        
        prepend_path(prefix)
      end
      
      # Rewrite the query string to inlcude body flag if necessary.
      def rewrite_query
        append_query('body=1') if options[:body]
      end
    end
  end
end
