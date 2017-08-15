module Utils
  class Logger
    @test_mode = false
    @verbose_mode = false

    class << self
      attr_accessor :test_mode
      attr_accessor :verbose_mode
    end

    def self.log_lint(message, file_name, line_number, context_hash)
      log "[INFO] #{message}:\n"
      log "[INFO]   #{file_name}:L#{line_number}\n"

      context_hash.each do |key, value|
        log "[INFO]   #{key}=`#{value}`\n"
      end

      log "\n"
    end

    def self.log_error(message, context_hash)
      if context_hash.nil?
        log "[ERROR] #{message}\n"
      else
        log "[ERROR] #{message}:\n"

        context_hash.each do |key, value|
          log "[ERROR]   #{key}=`#{value}`\n"
        end
      end

      log "\n"
    end

    def self.log_debug(line)
      print "[DEBUG] #{line}\n" if @verbose_mode
    end

    def self.log(line)
      print line unless @test_mode
    end
  end
end
