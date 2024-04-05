def get_added_swift_code(current_dir)
    swift_files = `git diff --name-only origin/master...`.split("\n").select do |file|
      file.downcase.end_with?('.swift') && !file.downcase.include?("test")
    end
  
    code_diff = swift_files.flat_map do |file|
      git_diff = `git diff origin/master... -- "#{file}"`
      git_diff.split("\n").select do |line|
        line.start_with?('+') && !line.start_with?('+++')
      end
    end
    code_diff
  end
  
  def check_spi_protection(added_lines)
    public_functions = []
  
    added_lines.each do |line|
      line = line.strip.delete_prefix('+')
      if line =~ /(public\s+)?func\s+\w+\s*\(/ and not line =~ /@_spi/
        public_functions << line.lstrip.chop
      end
    end
    public_functions
  end
  
  added_swift_code = get_added_swift_code($ROOT_DIR)
  new_public_apis = check_spi_protection(added_swift_code)
  puts(new_public_apis)
  if new_public_apis.any?
    File.open("new_public_apis.txt", 'w') { |f| f.write new_public_apis.join(", ") }
  end