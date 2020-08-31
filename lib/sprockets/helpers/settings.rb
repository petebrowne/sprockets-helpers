module Sprockets
  module Helpers
    class Settings
      # Link to assets from a dedicated server.
      attr_accessor :asset_host

      # When true, the asset paths will return digest paths.
      attr_accessor :digest

      # When true, expand assets.
      attr_accessor :expand

      # When true, force debug mode
      # :debug => true equals
      #   :expand   => true (unless using >= Sprockets 4.0)
      #   :digest   => false
      #   :manifest => false
      attr_accessor :debug

      # Set the Sprockets environment to search for assets.
      # This defaults to the context's #environment method.
      attr_accessor :environment

      # The manifest file used for lookup
      attr_accessor :manifest

      # The base URL the Sprocket environment is mapped to.
      # This defaults to '/assets'.
      def prefix
        @prefix ||= '/assets'
        @prefix.is_a?(Array) ? "/#{@prefix.first}" : @prefix
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

      # The default options for each asset path method. This is where you
      # can change your default directories for the fallback directory.
      def default_path_options
        @default_path_options ||= {
          :audio_path => { :dir => 'audios' },
          :font_path => { :dir => 'fonts' },
          :image_path => { :dir => 'images' },
          :javascript_path => { :dir => 'javascripts', :ext => 'js' },
          :stylesheet_path => { :dir => 'stylesheets', :ext => 'css' },
          :video_path => { :dir => 'videos' }
        }
      end
      attr_writer :default_path_options
    end
  end
end