require 'minitest/autorun'
require_relative '../framework_architecture_validator'

class FrameworkArchitectureValidatorTest < Minitest::Test
  FakeStatus = Struct.new(:successful) do
    def success?
      successful
    end
  end

  def test_accepts_matching_thin_architecture
    runner = command_runner(output: "arm64\n")

    result = FrameworkArchitectureValidator.verify(
      '/tmp/TestFramework',
      %w[arm64],
      command_runner: runner,
    )

    assert_equal %w[arm64], result
  end

  def test_accepts_matching_architectures_in_any_order
    runner = command_runner(output: "x86_64 arm64\n")

    result = FrameworkArchitectureValidator.verify(
      '/tmp/TestFramework',
      %w[arm64 x86_64],
      command_runner: runner,
    )

    assert_equal %w[arm64 x86_64], result
  end

  def test_rejects_an_architecture_mismatch
    runner = command_runner(output: "arm64\n")

    error = assert_raises(FrameworkArchitectureValidator::VerificationError) do
      FrameworkArchitectureValidator.verify(
        '/tmp/TestFramework',
        %w[arm64 x86_64],
        command_runner: runner,
      )
    end

    assert_equal(
      'Unexpected architectures for /tmp/TestFramework: expected arm64, x86_64, found arm64',
      error.message,
    )
  end

  def test_rejects_a_failed_lipo_inspection
    runner = command_runner(error: 'file is not a Mach-O binary', successful: false)

    error = assert_raises(FrameworkArchitectureValidator::VerificationError) do
      FrameworkArchitectureValidator.verify(
        '/tmp/TestFramework',
        %w[arm64],
        command_runner: runner,
      )
    end

    assert_equal(
      'Failed to inspect architectures for /tmp/TestFramework: file is not a Mach-O binary',
      error.message,
    )
  end

  private

  def command_runner(output: '', error: '', successful: true)
    lambda do |*arguments|
      assert_equal ['lipo', '-archs', '/tmp/TestFramework'], arguments
      [output, error, FakeStatus.new(successful)]
    end
  end
end
