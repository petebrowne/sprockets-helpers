module Sprockets
  module Helpers
    # `ManifestPath` uses the digest path and
    # prepends the prefix.
    class ManifestPath < AssetPath
      def initialize(uri, path, options = {})
        @uri = uri
        @options = options
        @options = {
          :body => false,
          :prefix => sprockets_helpers_settings.prefix
        }.merge options

        @uri.path = path.to_s
      end
    end
  end
end
