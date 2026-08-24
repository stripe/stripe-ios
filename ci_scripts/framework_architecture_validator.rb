require 'open3'

module FrameworkArchitectureValidator
  class VerificationError < StandardError; end

  module_function

  def verify(binary_path, expected_architectures, command_runner: Open3.method(:capture3))
    output, error, status = command_runner.call('lipo', '-archs', binary_path)
    unless status.success?
      raise VerificationError, "Failed to inspect architectures for #{binary_path}: #{error.strip}"
    end

    actual_architectures = output.split.sort
    expected_architectures = expected_architectures.sort
    unless actual_architectures == expected_architectures
      raise VerificationError,
        "Unexpected architectures for #{binary_path}: expected #{expected_architectures.join(', ')}, found #{actual_architectures.join(', ')}"
    end

    actual_architectures
  end
end
