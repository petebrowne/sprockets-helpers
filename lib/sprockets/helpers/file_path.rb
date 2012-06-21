require 'zlib'

module Sprockets
  module Helpers
    # `FilePath` generates a full path for a regular file
    # in the output path. It's used by #asset_path to generate
    # paths when using asset tags like #javascript_include_tag,
    # #stylesheet_link_tag, and #image_tag
    class FilePath
      # The parsed URI from which to generate the full path to the asset.
      attr_reader :uri
      
      # The various options used when generating the path.
      attr_reader :options
      
      # The base directory the file would be found in
      attr_reader :dir
    
      #
      def initialize(uri, options = {})
        @uri     = uri
        @options = options
        @dir     = options[:dir].to_s
      end
      
      # Returns the full path to the asset, complete with
      # timestamp.
      def to_s
        rewrite_base_path
        rewrite_query
        rewrite_host_and_protocol
        uri.to_s
      end
      
      protected
      
      # Hook for rewriting the base path.
      def rewrite_base_path # :nodoc:
        if uri.path[0] != ?/
          prepend_path(File.join('/', dir))
        end
      end
      
      # Hook for rewriting the query string.
      def rewrite_query # :nodoc:
        if timestamp = compute_mtime
          append_query(timestamp.to_i.to_s)
        end
      end
      
      # Hook for rewriting the host and protocol.
      def rewrite_host_and_protocol # :nodoc:
        if host = compute_host
          uri.host   = host
          uri.scheme = compute_scheme
        end
      end
      
      # Pick an asset host for this source. Returns +nil+ if no host is set,
      # the host if no wildcard is set, the host interpolated with the
      # numbers 0-3 if it contains <tt>%d</tt> (the number is the source hash mod 4),
      # or the value returned from invoking call on an object responding to call
      # (proc or otherwise).
      def compute_host # :nodoc:
        if host = options[:host] || Helpers.host
          if host.respond_to?(:call)
            host.call(uri.to_s)
          elsif host =~ /%d/
            host % (Zlib.crc32(uri.to_s) % 4)
          else
            host
          end
        end
      end
      
      # Pick a scheme for the protocol if we are using
      # an asset host.
      def compute_scheme # :nodoc:
        protocol = options[:protocol] || Helpers.protocol
        
        if protocol.nil? || protocol == :relative
          nil
        else
          protocol.to_s.sub %r{://\z}, ''
        end
      end
      
      # Returns the mtime for the given path (relative to
      # the output path). Returns nil if the file doesn't exist.
      def compute_mtime # :nodoc:
        public_path = File.join(Helpers.public_path, uri.path)
        
        if File.exist?(public_path)
          File.mtime(public_path)
        else
          nil
        end
      end
      
      # Prepends the given path. If the path is absolute
      # An attempt to merge the URIs is made.
      def prepend_path(value)
        prefix_uri = URI.parse(value)
        uri.path   = File.join prefix_uri.path, uri.path
        
        if prefix_uri.absolute?
          @uri = prefix_uri.merge(uri)
        end
      end
      
      # Append the given query string to the URI
      # instead of clobbering it.
      def append_query(value) # :nodoc:
        if uri.query.nil? || uri.query.empty? 
          uri.query = value
        else
          uri.query << ('&' + value)
        end
      end
    end
  end
end
