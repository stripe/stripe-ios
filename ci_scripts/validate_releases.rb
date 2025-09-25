#!/usr/bin/env ruby

require_relative 'release_common'
require 'tmpdir'
require 'zip'
require 'plist'

def download_and_extract_asset(release, asset_url, temp_dir)
  asset_path = File.join(temp_dir, "Stripe.xcframework.zip")

  # Download the asset
  rputs "Downloading #{asset_url}..."
  system("curl -L -o '#{asset_path}' '#{asset_url}'")

  unless File.exist?(asset_path)
    raise "Failed to download asset from #{asset_url}"
  end

  # Extract the zip file
  extract_dir = File.join(temp_dir, "extracted")
  FileUtils.mkdir_p(extract_dir)

  rputs "Extracting Stripe.xcframework.zip..."
  Zip::File.open(asset_path) do |zip_file|
    zip_file.each do |entry|
      entry.extract(File.join(extract_dir, entry.name))
    end
  end

  extract_dir
end

def get_bundle_version(extract_dir)
  # First, let's explore the structure to find the correct path
  rputs "Exploring extracted structure..."

  # Look for StripePaymentSheet.xcframework
  payment_sheet_paths = Dir.glob(File.join(extract_dir, "**/StripePaymentSheet.xcframework"))

  if payment_sheet_paths.empty?
    raise "StripePaymentSheet.xcframework not found in extracted directory"
  end

  payment_sheet_path = payment_sheet_paths.first
  rputs "Found StripePaymentSheet.xcframework at: #{payment_sheet_path}"

  # Look for ios-arm64 directory and Info.plist
  ios_arm64_paths = Dir.glob(File.join(payment_sheet_path, "**/ios-arm64"))

  if ios_arm64_paths.empty?
    # Try alternative architecture names
    arch_paths = Dir.glob(File.join(payment_sheet_path, "**/ios-*"))
    if arch_paths.empty?
      raise "No iOS architecture directories found in StripePaymentSheet.xcframework"
    end
    ios_arm64_path = arch_paths.first
  else
    ios_arm64_path = ios_arm64_paths.first
  end

  # The Info.plist is inside the .framework directory
  framework_path = File.join(ios_arm64_path, "StripePaymentSheet.framework")
  plist_path = File.join(framework_path, "Info.plist")

  unless File.exist?(plist_path)
    # List contents for debugging
    rputs "Contents of #{ios_arm64_path}:"
    Dir.entries(ios_arm64_path).each { |entry| rputs "  #{entry}" }
    if File.exist?(framework_path)
      rputs "Contents of #{framework_path}:"
      Dir.entries(framework_path).each { |entry| rputs "  #{entry}" }
    end
    raise "Info.plist not found at: #{plist_path}"
  end

  # Try to parse as XML first, then as binary plist
  begin
    plist = Plist.parse_xml(plist_path)
  rescue => e
    rputs "Failed to parse as XML plist, trying binary format..."
    # Convert binary plist to XML using plutil, then parse
    xml_content = `plutil -convert xml1 -o - '#{plist_path}'`
    if $?.exitstatus != 0
      raise "Failed to convert binary plist to XML: #{e.message}"
    end
    plist = Plist.parse_xml(xml_content)
  end

  bundle_version = plist['CFBundleVersion']

  unless bundle_version
    raise "CFBundleVersion not found in Info.plist"
  end

  bundle_version
end

def validate_release(release)
  rputs "Validating release #{release.tag_name}..."

  # Find the Stripe.xcframework.zip asset
  framework_asset = release.assets.find { |asset| asset.name == 'Stripe.xcframework.zip' }

  unless framework_asset
    rputs "❌ No Stripe.xcframework.zip asset found for release #{release.tag_name}".red
    return false
  end

  Dir.mktmpdir do |temp_dir|
    begin
      # Download and extract the asset
      extract_dir = download_and_extract_asset(release, framework_asset.browser_download_url, temp_dir)

      # Get the bundle version from Info.plist
      bundle_version = get_bundle_version(extract_dir)

      # Compare versions
      if bundle_version == release.tag_name
        rputs "✅ Release #{release.tag_name}: Bundle version matches (#{bundle_version})".green
        return true
      else
        rputs "❌ Release #{release.tag_name}: Bundle version mismatch! Expected: #{release.tag_name}, Found: #{bundle_version}".red
        return false
      end

    rescue => e
      rputs "❌ Release #{release.tag_name}: Validation failed with error: #{e.message}".red
      return false
    end
  end
end

def main
  rputs "Starting release validation for stripe/stripe-ios..."

  # Fetch more releases (GitHub API defaults to 30, we want 60)
  rputs "Fetching releases from GitHub..."
  releases = @github_client.releases('stripe/stripe-ios', per_page: 60)

  rputs "Found #{releases.length} releases"

  # Sort releases by tag name in descending order (assuming semantic versioning)
  sorted_releases = releases.sort_by { |r| Gem::Version.new(r.tag_name) }.reverse

  # Filter to start from version 24.6.0 and below
  start_version = Gem::Version.new('24.10.0')
  filtered_releases = sorted_releases.select { |r| Gem::Version.new(r.tag_name) <= start_version }

  rputs "Filtering to releases 24.6.0 and below: #{filtered_releases.length} releases"

  validation_results = []

  filtered_releases.each do |release|
    success = validate_release(release)
    validation_results << { release: release.tag_name, success: success }

    # Add a small delay to be respectful to GitHub's API
    sleep(1)
  end

  # Summary
  rputs "\n" + "="*50
  rputs "VALIDATION SUMMARY"
  rputs "="*50

  successful = validation_results.count { |r| r[:success] }
  total = validation_results.length

  validation_results.each do |result|
    status = result[:success] ? "✅" : "❌"
    rputs "#{status} #{result[:release]}"
  end

  rputs "\nTotal: #{successful}/#{total} releases validated successfully"

  if successful == total
    rputs "🎉 All releases passed validation!".green
    exit(0)
  else
    rputs "⚠️  Some releases failed validation.".red
    exit(1)
  end
end

# Check if required gems are available
begin
  require 'zip'
  require 'plist'
rescue LoadError => e
  rputs "Missing required gem: #{e.message}".red
  rputs "Please install required gems with:"
  rputs "  gem install rubyzip"
  rputs "  gem install plist"
  exit(1)
end

main
