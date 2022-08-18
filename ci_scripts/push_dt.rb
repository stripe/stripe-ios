#!/usr/bin/env ruby

if ARGV.empty?
  puts 'Data Theorem branch and API key missing'
  exit 101
end

datatheorem_endpoint = 'https://api.securetheorem.com/uploadapi/v1/upload_init'
target_branch = ARGV[0]
datatheorem_key = ARGV[1]

@build_path = `mktemp -d`.chomp("\n")
app_path = "#{@build_path}/build/IntegrationTesterArchived/Apps/IntegrationTester.ipa"

def build()

  # Xcode's ipatool relies on the system ruby, so break out of Bundler's environment here to avoid
  # "The data couldn’t be read because it isn’t in the correct format" errors.
  Bundler.with_original_env do

    # Build an archive with all code-signing disabled
    # (so we can run this in an untrusted CI environment)
    command_succeeded = system("#{'xcodebuild clean archive ' +
      '-quiet ' +
      '-workspace "Stripe.xcworkspace" ' +
      '-scheme "IntegrationTester" ' +
      '-sdk "iphoneos" ' +
      '-destination "generic/platform=iOS" ' +
      "-archivePath #{@build_path}/build/IntegrationTester.xcarchive " +
      'CODE_SIGN_IDENTITY="-" ' +
      'CODE_SIGNING_REQUIRED="NO" ' +
      'CODE_SIGN_ENTITLEMENTS="" ' +
      'CODE_SIGNING_ALLOWED="NO"'}")

    unless command_succeeded
      raise StandardError.new "Clean failed"
    end

    # Export a thinned archive for distribution using ad-hoc signing.
    # `ExportOptions.plist` contains a signingCertificate of "-": This isn't
    # documented anywhere, but will cause Xcode to ad-hoc sign the archive.
    # This will create "App Thinning Size Report.txt".
    command_succeeded = system("#{'xcodebuild -exportArchive ' +
    '-quiet '+
    "-archivePath #{@build_path}/build/IntegrationTester.xcarchive " +
    "-exportPath #{@build_path}/build/IntegrationTesterArchived " +
    '-exportOptionsPlist Tests/installation_tests/size_test/ExportOptions.plist ' +
    'CODE_SIGN_IDENTITY="-"'}")

    unless command_succeeded
      raise StandardError.new "Build failed"
    end
  end
end

def build_from_branch(branch)
  `git checkout #{branch}`
  build
end

build_from_branch(target_branch)

if !File.file?(app_path)
  exit 101
end

# we're using their recommended strategy here, hence the curl https://datatheorem.atlassian.net/servicedesk/customer/portal/1/article/1715241037
step1_response = `curl -X POST -H "Authorization: APIKey #{datatheorem_key}" --data "" #{datatheorem_endpoint}`
upload_url = `echo "#{step1_response}" | cut -f 3 -d" " | tr -d '"{}\n'`

# if this fails for some reason, it's ok, we can try again next build
step2_response = `curl -F file=@#{app_path} #{upload_url} --retry 3`

# purge build dir
FileUtils.rm_rf(@build_path)
