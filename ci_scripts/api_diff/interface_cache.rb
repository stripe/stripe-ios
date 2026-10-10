require 'digest'
require 'json'

module InterfaceCache
  FILENAMES = %w[arm64-apple-ios-simulator.swiftinterface arm64-apple-ios-simulator.private.swiftinterface].freeze
  class InvalidCache < StandardError; end

  def self.load!(directory, revision: nil, fingerprint: nil)
    manifest = JSON.parse(File.read(File.join(directory, 'manifest.json')))
    raise InvalidCache, 'invalid manifest' unless manifest.is_a?(Hash)
    raise InvalidCache, 'unexpected cache schema' unless manifest['version'] == 1
    raise InvalidCache, 'invalid revision' unless manifest['revision'].is_a?(String) && manifest['revision'].match?(/\A[0-9a-f]{40}\z/)
    raise InvalidCache, 'invalid fingerprint' unless manifest['fingerprint'].is_a?(String) && manifest['fingerprint'].match?(/\A[0-9a-f]{64}\z/)
    raise InvalidCache, 'invalid checksums' unless manifest['checksums'].is_a?(Hash)
    raise InvalidCache, 'different revision' if revision && manifest['revision'] != revision
    raise InvalidCache, 'different build recipe or toolchain' if fingerprint && manifest['fingerprint'] != fingerprint
    frameworks = manifest.fetch('frameworks')
    unless frameworks.is_a?(Array) && !frameworks.empty? && frameworks.uniq == frameworks &&
           frameworks.all? { |name| name.is_a?(String) && name.match?(/\A[A-Za-z_][A-Za-z0-9_]*\z/) }
      raise InvalidCache, 'invalid framework list'
    end
    frameworks.each do |framework|
      FILENAMES.each do |filename|
        relative_path = File.join(framework, filename)
        path = File.join(directory, relative_path)
        unless File.file?(path) && File.size?(path) && Digest::SHA256.file(path).hexdigest == manifest.fetch('checksums')[relative_path]
          raise InvalidCache, "missing or invalid interface: #{relative_path}"
        end
      end
    end
    manifest
  rescue JSON::ParserError, Errno::ENOENT, KeyError, TypeError => e
    raise InvalidCache, e.message
  end

  def self.write!(directory, revision:, fingerprint:, frameworks:)
    checksums = frameworks.product(FILENAMES).to_h do |framework, filename|
      relative_path = File.join(framework, filename)
      [relative_path, Digest::SHA256.file(File.join(directory, relative_path)).hexdigest]
    end
    File.write(File.join(directory, 'manifest.json'), JSON.pretty_generate(
      version: 1, revision: revision, fingerprint: fingerprint, frameworks: frameworks, checksums: checksums
    ))
    load!(directory, revision: revision, fingerprint: fingerprint)
  end
end
