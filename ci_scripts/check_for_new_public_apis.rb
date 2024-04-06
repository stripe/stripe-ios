def get_modified_swift_files(current_dir)
  files = `git diff --name-only origin/master...`.split("\n").select { |f| f.downcase.end_with?(".swift") && !f.downcase.include?("test") }
  files.select { |f| File.exist?(f) }
end

def get_added_lines_change(file)
  `git diff origin/master... -- '#{file}'`.split("\n").select do |line|
    line.start_with?('+') && !line.start_with?('+++')
  end.map { |line| line.delete_prefix('+').strip }
end

def check_spi_protection(file)
  in_spi_protected_block = false
  block_depth = 0
  public_items = []
  added_lines = get_added_lines_change(file)
  previous_line_spi_annotated = false


  File.foreach(file) do |line|
    line = line.strip
    opening_braces = line.count('{')
    closing_braces = line.count('}')
    
    block_depth += opening_braces - closing_braces
    if line =~ /@_spi\(\w+\)\s+(public\s+)?(class|struct|enum|protocol)\s+\w+/ && opening_braces > 0
      in_spi_protected_block = true
    elsif line =~ /(public\s+)?(class|struct|enum|protocol)\s+\w+/ && opening_braces > 0
      in_spi_protected_block = false
    elsif added_lines.include?(line) && line =~ /(public\s+|open\s+)[a-z]+\s+\w+/ && !in_spi_protected_block && !previous_line_spi_annotated
      public_items << (File.basename(file) + ": " + line.lstrip.chomp('{').rstrip)
    end

    previous_line_spi_annotated = line.include?("@_spi(")
    in_spi_protected_block = false if block_depth == 0
  end

  public_items
end

files = get_modified_swift_files($ROOT_DIR)
new_public_items = files.flat_map { |file| check_spi_protection(file) }

if new_public_items.any?
  puts new_public_items
  File.open("new_public_items.txt", 'w') { |f| f.write new_public_items.join("\n") }
end