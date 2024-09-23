#!/usr/bin/env ruby

def validate_version_number_format(version_number)
  part_names = ['major', 'minor', 'patch']
  parts = version_number.split('.')

  unless parts.length() == 3
    abort("Invalid version number. It should consist of a major, minor, and patch number.")
  end

  parts.each_with_index do | part, index |
    if part.start_with?('0') && part.length() > 1
      part_name = part_names[index]
      abort("Invalid version number: #{part_name} number can\'t begin with 0.")
    end
  end
end

def target_version_is_newer(target_version, current_version)
  target_major, target_minor, target_patch = target_version.split('.')
  current_major, current_minor, current_patch = current_version.split('.')

  if target_major < current_major
    false
  elsif target_major > current_major
    true
  elsif target_minor < current_minor
    false
  elsif target_minor > current_minor
    true
  else
    target_patch > current_patch
  end
end

def get_current_version()
  latest_version = File.read('VERSION')
  latest_version
end

def validate_target_version_is_newer(target_version)
    current_version = get_current_version()
    if !target_version_is_newer(target_version, current_version)
        raise "Expected target version #{target_version} to be newer than #{current_version}."
    end
end

def validate_version_number()
    validate_version_number_format(@version)
    validate_target_version_is_newer(@version)
end
