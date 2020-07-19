module Sprockets
  module Helpers
    # `AssetPath` generates a full path for an asset
    # that exists in Sprockets environment.
    class AssetPath < BasePath
      def initialize(uri, asset, environment, options = {})
        @uri = uri
        @asset = asset
        @environment = environment
        @options = options
        @options = {
          :body => false,
          :digest => sprockets_helpers_settings.digest,
          :prefix => sprockets_helpers_settings.prefix
        }.merge options

        @uri.path = @options[:digest] ? asset.digest_path : asset.logical_path
      end

      def to_a
        if @asset.respond_to?(:to_a)
          @asset.to_a.map do |dependency|
            AssetPath.new(@uri.clone, dependency, @environment, @options.merge(:body => true)).to_s
          end
        elsif @asset.metadata[:included]
          @asset.metadata[:included].map do |uri|
            AssetPath.new(@uri.clone, @environment.load(uri), @environment, @options.merge(:body => true)).to_s
          end
        else
          AssetPath.new(@uri.clone, @asset, @environment, @options.merge(:body => true)).to_s
        end
      end

      protected

      def rewrite_path
        prefix = if options[:prefix].respond_to? :call
          warn 'DEPRECATION WARNING: Using a Proc for Sprockets::Helpers.prefix is deprecated and will be removed in 1.0. Please use Sprockets::Helpers.asset_host instead.'
          options[:prefix].call uri.path
        else
          options[:prefix].to_s
        end

        prepend_path(prefix)
      end

      def rewrite_query
        append_query('body=1') if options[:body]
      end
    end
  end
end
