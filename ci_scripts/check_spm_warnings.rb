#!/usr/bin/env ruby

puts 'Checking for SPM warnings...'

spm_results = `swift build --target none 2>&1`
warnings = spm_results.lines.filter { |line| line.include?('warning') }.join('\n')
abort("Package.swift contains warnings:\n#{warnings}\nOpen Package.swift to view/resolve.") unless warnings.empty?

puts 'No warnings!'
