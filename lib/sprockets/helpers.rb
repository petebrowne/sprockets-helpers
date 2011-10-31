require "sprockets/helpers/version"
require "sprockets"

module Sprockets
  module Helpers
    autoload :AssetPath, "sprockets/helpers/asset_path"
    autoload :FilePath,  "sprockets/helpers/file_path"
    
    # Pattern for checking if a given path is an external URI.
    URI_MATCH = %r(^[-a-z]+://|^cid:|^//)
    
    class << self
      # When true, the asset paths will return digest paths.
      attr_accessor :digest
      
      # The base URL the Sprocket environment is mapped to.
      # This defaults to "/assets".
      def prefix
        @prefix ||= "/assets"
      end
      attr_writer :prefix
      
      # The path to the public directory, where the assets
      # not managed by Sprockets will be located.
      # Defaults to "./public"
      def public_path
        @public_path ||= "./public"
      end
      attr_writer :public_path
    end
    
    #
    def asset_path(source, options = {})
      return source if source =~ URI_MATCH
      
      # Append extension if necessary
      if options[:ext] && File.extname(source).empty?
        source << ".#{options[:ext]}"
      end
        
      # If the source points to an asset in the Sprockets
      # environment use AssetPath to generate the full path.
      environment.resolve(source) do |path|
        return AssetPath.new(environment.find_asset(path), options).to_s
      end
      
      # Use FilePath for normal files on the file system
      FilePath.new(source, options).to_s
    end
    
    #
    def javascript_path(source, options = {})
      asset_path source, { :dir => "javascripts", :ext => "js" }.merge(options)
    end
    
    #
    def stylesheet_path(source, options = {})
      asset_path source, { :dir => "stylesheets", :ext => "css" }.merge(options)
    end
    
    #
    def image_path(source, options = {})
      asset_path source, { :dir => "images" }.merge(options)
    end
  end
  
  class Context
    include Helpers
  end
end
