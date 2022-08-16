#!/usr/bin/env ruby

# frozen_string_literal: true

require 'json'
require 'colorize'
require 'optparse'
require_relative 'lib/metadata'

options = {}

OptionParser.new do |opts|
  opts.banner = 'Usage: extract.rb [options] metadata.xml [destination.json]'

  opts.on('-c', '--compress', 'Compress with LZFSE.') do |c|
    options[:compress] = c
  end

  opts.on('-f', '--fallback', 'Generate fallback metadata.') do |f|
    options[:fallback] = f
  end
end.parse!

abort('Please specify a path to metadata.xml'.red) if ARGV.length.zero?

metadata = PhoneMetadata::Metadata.load(ARGV[0])
result = metadata.get(fallback: options[:fallback])

if ARGV[1].nil?
  # Print to STDOUT.
  if options[:compress]
    abort('Cannot print compressed data to STDOUT. Please specify a path.'.red)
  else
    puts JSON.pretty_generate(result)
  end
elsif options[:compress]
  # Write to disk compressed.
  PhoneMetadata::Utils.write_lzfse_file(ARGV[1], result.to_json)
else
  # Write to distk uncompressed.
  File.write(ARGV[1], JSON.pretty_generate(result))
end
