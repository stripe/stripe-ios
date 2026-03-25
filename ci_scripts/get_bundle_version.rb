#!/usr/bin/env ruby

require 'fileutils'
require 'tmpdir'
require 'plist'
require_relative 'release_common'

# Helper method to extract the bundle version from the xcframework is the expected value
def get_bundle_version(xcframework_zip)
  # Extract zip file
  Dir.mktmpdir do |temp_dir|
    unless system("unzip", "-q", xcframework_zip, "-d", temp_dir)
      raise "Failed to unzip #{xcframework_zip}"
    end
    
    # Look for StripePaymentSheet.xcframework
    payment_sheet_paths = Dir.glob(File.join(temp_dir, "**/StripePaymentSheet.xcframework"))
    
    if payment_sheet_paths.empty?
      raise "StripePaymentSheet.xcframework not found in extracted directory"
    end
    
    payment_sheet_path = payment_sheet_paths.first
    
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
    
    # Convert binary plist to XML using plutil, then parse
    xml_content = `plutil -convert xml1 -o - '#{plist_path}'`
    if $?.exitstatus != 0
      raise "Failed to convert binary plist to XML"
    end
    plist = Plist.parse_xml(xml_content)
    
    bundle_version = plist['CFBundleVersion']
    
    unless bundle_version
      raise "CFBundleVersion not found in Info.plist"
    end
    
    bundle_version
  end
end


# Main execution
if __FILE__ == $0
  def version_from_file
    # Get version from VERSION
    version = 'failed to find version'
    File.open('VERSION', 'r') do |f|
      version = f.read.chomp
    end
    version
  end

  zip_file = "build/Stripe.xcframework.zip"
  bundle_version = get_bundle_version(zip_file)
  puts "The bundle version in build/Stripe.xcframework is #{bundle_version}"
  raise "build/Stripe.xcframework bundle version (#{bundle_version}) doesn't match the VERSION file (#{version_from_file})!" unless bundle_version == version_from_file

end
