module Sprockets
  module Helpers
    # `ManifestPath` uses the digest path and
    # prepends the prefix.
    class ManifestPath < AssetPath
      #
      def initialize(path, options = {})
        @options = {
          :body   => false,
          :prefix => Helpers.prefix
        }.merge options
        
        @source = path.to_s
      end
    end
  end
end
