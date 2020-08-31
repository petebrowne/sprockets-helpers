require 'sprockets'
require 'sprockets/helpers/version'
require 'sprockets/helpers/base_path'
require 'sprockets/helpers/asset_path'
require 'sprockets/helpers/file_path'
require 'sprockets/helpers/manifest_path'
require 'sprockets/helpers/settings'
require 'uri'
require 'forwardable'

module Sprockets
  module Helpers
    class << self
      extend Forwardable

      # Indicates whenever we are using Sprockets 3.x or higher.
      attr_accessor :are_using_sprockets_3_plus

      # Indicates whenever we are using Sprockets 4.x or higher.
      attr_accessor :are_using_sprockets_4_plus

      # Settings of Sprockets::Helpers
      attr_accessor :settings

      # Access the settings directly for compatibility purposes.
      def_delegators :@settings, *Settings.public_instance_methods(false)

      # Convience method for configuring Sprockets::Helpers.
      def configure
        yield settings
      end

      # Hack to ensure methods from Sprockets::Helpers override the
      # methods of Sprockets::Context when included.
      def append_features(context) # :nodoc:
        context.class_eval do
          context_methods = context.instance_methods(false)
          Helpers.public_instance_methods.each do |method|
            remove_method(method) if context_methods.include?(method)
          end
        end

        super(context)
      end
    end

    @settings = Settings.new

    # We are checking here to skip this at runtime
    @are_using_sprockets_3_plus = Gem::Version.new(Sprockets::VERSION) >= Gem::Version.new('3.0')
    @are_using_sprockets_4_plus = Gem::Version.new(Sprockets::VERSION) >= Gem::Version.new('4.0')

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
      return source if uri.absolute?

      options[:prefix] = sprockets_helpers_settings.prefix unless options[:prefix]

      if sprockets_helpers_settings.debug || options[:debug]
        options[:manifest] = false
        options[:digest] = false
        options[:asset_host] = false
      end

      source_ext = File.extname(source)

      if options[:ext] && source_ext != ".#{options[:ext]}"
        uri.path << ".#{options[:ext]}"
      end

      path = find_asset_path(uri, source, options)
      if options[:expand] && path.respond_to?(:to_a)
        path.to_a
      else
        path.to_s
      end
    end
    alias_method :path_to_asset, :asset_path

    def asset_tag(source, options = {}, &block)
      raise ::ArgumentError, 'block missing' unless block
      options = { :expand => (!!sprockets_helpers_settings.debug && !::Sprockets::Helpers.are_using_sprockets_4_plus) || 
                             !!sprockets_helpers_settings.expand,
                  :debug => sprockets_helpers_settings.debug }.merge(options)

      path = asset_path(source, options)
      output = if options[:expand] && path.respond_to?(:map)
        "\n<!-- Expanded from #{source} -->\n" + path.map(&block).join("\n")
      else
        yield path
      end

      output = output.html_safe if output.respond_to?(:html_safe)
      output
    end

    def javascript_tag(source, options = {})
      options = sprockets_helpers_settings.default_path_options[:javascript_path].merge(options)
      asset_tag(source, options) do |path|
        %Q(<script src="#{path}" type="text/javascript"></script>)
      end
    end

    def stylesheet_tag(source, options = {})
      media = options.delete(:media)
      media_attr = media.nil? ? nil : " media=\"#{media}\""
      options = sprockets_helpers_settings.default_path_options[:stylesheet_path].merge(options)
      asset_tag(source, options) do |path|
        %Q(<link rel="stylesheet" type="text/css" href="#{path}"#{media_attr}>)
      end
    end

    # Computes the path to a audio asset either in the Sprockets environment
    # or the public directory. External URIs are untouched.
    #
    # ==== Examples
    #
    # With files within Sprockets:
    #
    #   audio_path 'audio.mp3'            # => '/assets/audio.mp3'
    #   audio_path 'subfolder/audio.mp3'  # => '/assets/subfolder/audio.mp3'
    #   audio_path '/subfolder/audio.mp3' # => '/assets/subfolder/audio.mp3'
    #
    # With files outside of Sprockets:
    #
    #   audio_path 'audio'                                # => '/audios/audio'
    #   audio_path 'audio.mp3'                            # => '/audios/audio.mp3'
    #   audio_path 'subfolder/audio.mp3'                  # => '/audios/subfolder/audio.mp3'
    #   audio_path '/subfolder/audio.mp3                  # => '/subfolder/audio.mp3'
    #   audio_path 'http://www.example.com/img/audio.mp3' # => 'http://www.example.com/img/audio.mp3'
    #
    def audio_path(source, options = {})
      asset_path source, sprockets_helpers_settings.default_path_options[:audio_path].merge(options)
    end
    alias_method :path_to_audio, :audio_path

    # Computes the path to a font asset either in the Sprockets environment
    # or the public directory. External URIs are untouched.
    #
    # ==== Examples
    #
    # With files within Sprockets:
    #
    #   font_path 'font.ttf'            # => '/assets/font.ttf'
    #   font_path 'subfolder/font.ttf'  # => '/assets/subfolder/font.ttf'
    #   font_path '/subfolder/font.ttf' # => '/assets/subfolder/font.ttf'
    #
    # With files outside of Sprockets:
    #
    #   font_path 'font'                                # => '/fonts/font'
    #   font_path 'font.ttf'                            # => '/fonts/font.ttf'
    #   font_path 'subfolder/font.ttf'                  # => '/fonts/subfolder/font.ttf'
    #   font_path '/subfolder/font.ttf                  # => '/subfolder/font.ttf'
    #   font_path 'http://www.example.com/img/font.ttf' # => 'http://www.example.com/img/font.ttf'
    #
    def font_path(source, options = {})
      asset_path source, sprockets_helpers_settings.default_path_options[:font_path].merge(options)
    end
    alias_method :path_to_font, :font_path

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
      asset_path source, sprockets_helpers_settings.default_path_options[:image_path].merge(options)
    end
    alias_method :path_to_image, :image_path

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
      asset_path source, sprockets_helpers_settings.default_path_options[:javascript_path].merge(options)
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
      asset_path source, sprockets_helpers_settings.default_path_options[:stylesheet_path].merge(options)
    end
    alias_method :path_to_stylesheet, :stylesheet_path

    # Computes the path to a video asset either in the Sprockets environment
    # or the public directory. External URIs are untouched.
    #
    # ==== Examples
    #
    # With files within Sprockets:
    #
    #   video_path 'video.mp4'            # => '/assets/video.mp4'
    #   video_path 'subfolder/video.mp4'  # => '/assets/subfolder/video.mp4'
    #   video_path '/subfolder/video.mp4' # => '/assets/subfolder/video.mp4'
    #
    # With files outside of Sprockets:
    #
    #   video_path 'video'                                # => '/videos/video'
    #   video_path 'video.mp4'                            # => '/videos/video.mp4'
    #   video_path 'subfolder/video.mp4'                  # => '/videos/subfolder/video.mp4'
    #   video_path '/subfolder/video.mp4                  # => '/subfolder/video.mp4'
    #   video_path 'http://www.example.com/img/video.mp4' # => 'http://www.example.com/img/video.mp4'
    #
    def video_path(source, options = {})
      asset_path source, sprockets_helpers_settings.default_path_options[:video_path].merge(options)
    end
    alias_method :path_to_video, :video_path

    protected

    # Returns the Sprockets environment #asset_path uses to search for
    # assets. This can be overridden for more control, if necessary.
    # For even more control, you just need to override #sprockets_helper_settings.
    # Defaults to sprockets_helpers_settings.environment or the environment
    # returned by #environment.
    def assets_environment
      sprockets_helpers_settings.environment || environment
    end
    
    # Returns the Sprockets helpers settings. This can be overridden for
    # more control, for instance if you want to support polyinstantiation
    # in your application.
    def sprockets_helpers_settings
      Helpers.settings
    end

    def find_asset_path(uri, source, options = {})
      options = options.merge(:sprockets_helpers_settings => sprockets_helpers_settings,
                              :debug => sprockets_helpers_settings.debug)

      if sprockets_helpers_settings.manifest && options[:manifest] != false
        manifest_path = sprockets_helpers_settings.manifest.assets[uri.path]
        return Helpers::ManifestPath.new(uri, manifest_path, options) if manifest_path
      end

      if Sprockets::Helpers.are_using_sprockets_4_plus
        resolved, _ = assets_environment.resolve(uri.path, pipeline: options[:debug] ? :debug : nil)

        if resolved
          return Helpers::AssetPath.new(uri, assets_environment[uri.path, pipeline: options[:debug] ? :debug : nil], assets_environment, options)
        else
          return Helpers::FilePath.new(uri, options)
        end
      elsif Sprockets::Helpers.are_using_sprockets_3_plus
        resolved, _ = assets_environment.resolve(uri.path)

        if resolved
          return Helpers::AssetPath.new(uri, assets_environment[uri.path], assets_environment, options)
        else
          return Helpers::FilePath.new(uri, options)
        end
      else
        assets_environment.resolve(uri.path) do |path|
          return Helpers::AssetPath.new(uri, assets_environment[path], assets_environment, options)
        end

        return Helpers::FilePath.new(uri, options)
      end
    end
  end

  class Context
    include Helpers
  end
end
