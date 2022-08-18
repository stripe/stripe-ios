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

  opts.on('-p', '--print', 'Print output to STDOUT.') do |p|
    options[:print] = p
  end
end.parse!

abort('Please specify a path to metadata.xml'.red) if ARGV.length.zero?

metadata = PhoneMetadata::Metadata.load(ARGV[0])
result = metadata.get(fallback: options[:fallback])

if options[:print]
  # Print to STDOUT.
  if options[:compress]
    abort('Cannot print compressed data to STDOUT.'.red)
  else
    puts JSON.pretty_generate(result)
  end
elsif ARGV[1].nil?
  abort('Please specify a destination path.'.red)
elsif options[:compress]
  # Write to disk compressed.
  PhoneMetadata::Utils.write_lzfse_file(ARGV[1], result.to_json)
else
  # Write to disk uncompressed.
  File.write(ARGV[1], JSON.pretty_generate(result))
end
