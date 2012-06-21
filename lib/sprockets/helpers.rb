require 'sprockets/helpers/version'
require 'sprockets'
require 'uri'

module Sprockets
  module Helpers
    autoload :AssetPath,    'sprockets/helpers/asset_path'
    autoload :FilePath,     'sprockets/helpers/file_path'
    autoload :ManifestPath, 'sprockets/helpers/manifest_path'
    
    class << self
      # When true, the asset paths will return digest paths.
      attr_accessor :digest
      
      # Set the Sprockets environment to search for assets.
      # This defaults to the context's #environment method.
      attr_accessor :environment
      
      # Link to assets from a dedicated server.
      attr_accessor :host
      
      # The manifest file used for lookup
      attr_accessor :manifest
      
      # The base URL the Sprocket environment is mapped to.
      # This defaults to '/assets'.
      def prefix
        @prefix ||= '/assets'
      end
      attr_writer :prefix
      
      # Customize the protocol when using asset hosts.
      # If the value is :relative, A relative protocol ('//')
      # will be used.
      def protocol
        @protocol ||= 'http://'
      end
      attr_writer :protocol
      
      # The path to the public directory, where the assets
      # not managed by Sprockets will be located.
      # Defaults to './public'
      def public_path
        @public_path ||= './public'
      end
      attr_writer :public_path
      
      # Convience method for configuring Sprockets::Helpers.
      def configure
        yield self
      end
    end
    
    # Returns the path to an asset either in the Sprockets environment
    # or the public directory. External URIs are untouched.
    #
    # ==== Options
    #
    # * <tt>:ext</tt> - The extension to append if the source does not have one.
    # * <tt>:dir</tt> - The directory to prepend if the file is in the public directory.
    # * <tt>:digest</tt> - Wether or not use the digest paths for assets. Set Sprockets::Helpers.digest for global configuration.
    # * <tt>:prefix</tt> - Use a custom prefix for the Sprockets environment. Set Sprockets::Helpers.prefix for global configuration.
    # * <tt>:body</tt> - Adds a ?body=1 flag that tells Sprockets to return only the body of the asset.
    #
    # ==== Examples
    #
    # For files within Sprockets:
    #
    #   asset_path 'xmlhr.js'                       # => '/assets/xmlhr.js'
    #   asset_path 'xmlhr', :ext => 'js'            # => '/assets/xmlhr.js'
    #   asset_path 'xmlhr.js', :digest => true      # => '/assets/xmlhr-27a8f1f96afd8d4c67a59eb9447f45bd.js'
    #   asset_path 'xmlhr.js', :prefix => '/themes' # => '/themes/xmlhr.js'
    #
    # For files outside of Sprockets:
    #
    #   asset_path 'xmlhr'                                # => '/xmlhr'
    #   asset_path 'xmlhr', :ext => 'js'                  # => '/xmlhr.js'
    #   asset_path 'dir/xmlhr.js', :dir => 'javascripts'  # => '/javascripts/dir/xmlhr.js'
    #   asset_path '/dir/xmlhr.js', :dir => 'javascripts' # => '/dir/xmlhr.js'
    #   asset_path 'http://www.example.com/js/xmlhr'      # => 'http://www.example.com/js/xmlhr'
    #   asset_path 'http://www.example.com/js/xmlhr.js'   # => 'http://www.example.com/js/xmlhr.js'
    # 
    def asset_path(source, options = {})
      uri = URI.parse(source)
      
      # Return fast if the URI is absolute
      return source if uri.absolute?
      
      # Append extension if necessary
      if options[:ext] && File.extname(uri.path).empty?
        uri.path << ".#{options[:ext]}"
      end
      
      # If a manifest is present, try to grab the path from the manifest first
      if Helpers.manifest && Helpers.manifest.assets[uri.path]
        return ManifestPath.new(uri, Helpers.manifest.assets[uri.path], options).to_s
      end
      
      # If the source points to an asset in the Sprockets
      # environment use AssetPath to generate the full path.
      assets_environment.resolve(uri.path) do |path|
        return AssetPath.new(uri, assets_environment[path], options).to_s
      end
      
      # Use FilePath for normal files on the file system
      FilePath.new(uri, options).to_s
    end
    alias_method :path_to_asset, :asset_path
    
    # Computes the path to a javascript asset either in the Sprockets
    # environment or the public directory. If the +source+ filename has no extension,
    # <tt>.js</tt> will be appended. External URIs are untouched.
    #
    # ==== Examples
    #
    # For files within Sprockets:
    #
    #   javascript_path 'xmlhr'        # => '/assets/xmlhr.js'
    #   javascript_path 'dir/xmlhr.js' # => '/assets/dir/xmlhr.js'
    #   javascript_path '/dir/xmlhr'   # => '/assets/dir/xmlhr.js'
    #
    # For files outside of Sprockets:
    #
    #   javascript_path 'xmlhr'                              # => '/javascripts/xmlhr.js'
    #   javascript_path 'dir/xmlhr.js'                       # => '/javascripts/dir/xmlhr.js'
    #   javascript_path '/dir/xmlhr'                         # => '/dir/xmlhr.js'
    #   javascript_path 'http://www.example.com/js/xmlhr'    # => 'http://www.example.com/js/xmlhr'
    #   javascript_path 'http://www.example.com/js/xmlhr.js' # => 'http://www.example.com/js/xmlhr.js'
    #
    def javascript_path(source, options = {})
      asset_path source, { :dir => 'javascripts', :ext => 'js' }.merge(options)
    end
    alias_method :path_to_javascript, :javascript_path
    
    # Computes the path to a stylesheet asset either in the Sprockets
    # environment or the public directory. If the +source+ filename has no extension,
    # <tt>.css</tt> will be appended. External URIs are untouched.
    #
    # ==== Examples
    #
    # For files within Sprockets:
    #
    #   stylesheet_path 'style'          # => '/assets/style.css'
    #   stylesheet_path 'dir/style.css'  # => '/assets/dir/style.css'
    #   stylesheet_path '/dir/style.css' # => '/assets/dir/style.css'
    #
    # For files outside of Sprockets:
    #
    #   stylesheet_path 'style'                                  # => '/stylesheets/style.css'
    #   stylesheet_path 'dir/style.css'                          # => '/stylesheets/dir/style.css'
    #   stylesheet_path '/dir/style.css'                         # => '/dir/style.css'
    #   stylesheet_path 'http://www.example.com/css/style'       # => 'http://www.example.com/css/style'
    #   stylesheet_path 'http://www.example.com/css/style.css'   # => 'http://www.example.com/css/style.css'
    #
    def stylesheet_path(source, options = {})
      asset_path source, { :dir => 'stylesheets', :ext => 'css' }.merge(options)
    end
    alias_method :path_to_stylesheet, :stylesheet_path
    
    # Computes the path to an image asset either in the Sprockets environment
    # or the public directory. External URIs are untouched.
    #
    # ==== Examples
    #
    # With files within Sprockets:
    #
    #   image_path 'edit.png'        # => '/assets/edit.png'
    #   image_path 'icons/edit.png'  # => '/assets/icons/edit.png'
    #   image_path '/icons/edit.png' # => '/assets/icons/edit.png'
    #
    # With files outside of Sprockets:
    #
    #   image_path 'edit'                                # => '/images/edit'
    #   image_path 'edit.png'                            # => '/images/edit.png'
    #   image_path 'icons/edit.png'                      # => '/images/icons/edit.png'
    #   image_path '/icons/edit.png'                     # => '/icons/edit.png'
    #   image_path 'http://www.example.com/img/edit.png' # => 'http://www.example.com/img/edit.png'
    #
    def image_path(source, options = {})
      asset_path source, { :dir => 'images' }.merge(options)
    end
    alias_method :path_to_image, :image_path
    
    protected
    
    # Returns the Sprockets environment #asset_path uses to search for
    # assets. This can be overridden for more control, if necessary.
    # Defaults to Sprockets::Helpers.environment or the envrionment
    # returned by #environment.
    def assets_environment
      Helpers.environment || environment
    end
  end
  
  class Context
    include Helpers
  end
end
