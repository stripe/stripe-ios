# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'open3'
require 'tmpdir'

# Newer releases have produced duplicate declarations when indexing mixed Swift/ObjC targets.
PERIPHERY_VERSION = '3.6.0'
PERIPHERY_SHA256 = '983cb6bad09b7030f0ec151e05f650dbf450eb624bd361a0ad89c59fdbf18182'

abort 'Usage: run_scan.rb COMMIT OUTPUT_JSON' unless ARGV.length == 2
commit, output = ARGV
abort 'Expected an immutable commit' unless commit.match?(/\A[0-9a-f]{40}\z/)

root = File.expand_path('../..', __dir__)
output = File.expand_path(output)
FileUtils.mkdir_p(File.dirname(output))
FileUtils.rm_f(output)
tool_dir = File.join(ENV.fetch('RUNNER_TEMP'), 'dead-code-tools')
FileUtils.mkdir_p(tool_dir)
binary = File.join(tool_dir, 'periphery')

unless File.executable?(binary)
  archive = File.join(tool_dir, 'periphery.zip')
  url = "https://github.com/peripheryapp/periphery/releases/download/#{PERIPHERY_VERSION}/periphery-#{PERIPHERY_VERSION}.zip"
  system('curl', '--fail', '--location', '--retry', '3', url, '--output', archive, exception: true)
  abort 'Periphery download checksum mismatch' unless Digest::SHA256.file(archive).hexdigest == PERIPHERY_SHA256

  system('unzip', '-o', archive, '-d', tool_dir, exception: true)
end

Dir.mktmpdir('dead-code-scan-', ENV.fetch('RUNNER_TEMP')) do |temporary|
  source = root
  current, status = Open3.capture2('git', '-C', root, 'rev-parse', 'HEAD')
  abort 'Could not determine checkout commit' unless status.success?

  begin
    if current.strip != commit
      source = File.join(temporary, 'baseline')
      system('git', '-C', root, 'worktree', 'add', '--detach', source, commit, exception: true)
      # Compare both revisions using precisely the same scan configuration.
      FileUtils.cp(File.join(root, '.periphery.yml'), File.join(source, '.periphery.yml'))
    end
    report = File.join(temporary, 'periphery.txt')
    succeeded = system(binary, 'scan', '--config', '.periphery.yml', '--clean-build', '--retain-codable-properties',
                       chdir: source, out: report, err: [:child, :out])
    unless succeeded
      warn File.readlines(report).last(100).join
      abort "Periphery scan failed for #{commit}"
    end
    system('ruby', File.join(__dir__, 'process_periphery_output.rb'), report, output, exception: true)
  ensure
    system('git', '-C', root, 'worktree', 'remove', '--force', source) if source != root
  end
end
