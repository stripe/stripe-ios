# frozen_string_literal: true

module CIChangeScope
  def self.non_production_path?(path)
    # Build configuration can change the SDK graph even inside an example or test directory.
    return false if path.match?(/(?:\.(?:xcodeproj|xcworkspace)\/|\.(?:pbxproj|xcconfig|xcscheme|podspec|ya?ml|sh|rb)$|(?:\A|\/)(?:Package\.swift|Package\.resolved|Podfile(?:\.lock)?|Gemfile(?:\.lock)?|Makefile)$)/)

    path.start_with?('Example/', 'Testers/', 'Tests/') ||
      path.match?(%r{\AStripe[^/]*/(?:[^/]*Tests|[^/]*UITests)/}) ||
      %w[README.md CHANGELOG.md CONTRIBUTING.md LICENSE].include?(path)
  end

  def self.scan_required?(paths)
    paths.any? { |path| !non_production_path?(path) }
  end
end
