#!/usr/bin/env ruby

require 'colorize'
require 'English'

def rputs(string)
  puts string.red
end

def run_command(command, throw_on_failure = true)
  puts "> #{command}".blue
  system(command.to_s)
  return unless $CHILD_STATUS.exitstatus != 0

  rputs "Command failed: #{command} \a"
  raise if throw_on_failure
end
