#!/usr/bin/env ruby
# frozen_string_literal: true

# Sorts Swift interface files alphabetically for consistent diffing
# Usage: ruby sort_swift_interface.rb <input_file> <output_file>

# This was entirely written by Claude Code to quickly fix our API checker. It just helps us
# sort the file and notice changes in the diff. I would not recommend repurposing it for any other reason!

class SwiftInterfaceNode
  attr_accessor :lines, :children, :indent_level, :sort_key, :member_group

  def initialize(indent_level)
    @lines = [] # Lines that make up the declaration header and opening brace
    @indent_level = indent_level
    @children = []
    @sort_key = ''
    @member_group = 0
  end

  def finalize
    @sort_key = extract_sort_key
    @member_group = determine_member_group
  end

  def extract_sort_key
    # Find the line with the actual declaration
    declaration_line = lines.find { |line| line.strip.match?(/^(public|@objc|extension|#if|final|@_)/) }
    return '' unless declaration_line

    clean_line = declaration_line.strip

    # Handle different declaration types
    case clean_line
    when /^extension\s+(\S+)/
      $1.split('.').last
    when /^(?:@objc\s+)?public\s+(?:static\s+)?(?:let|var|weak|unowned)\s+(\w+)/
      $1
    when /^(?:@objc|@_\w+|public|final|@frozen).*?(?:class|struct|protocol|enum)\s+(\w+)/
      $1
    when /^(?:@objc.*?)?(?:init|func|convenience|required)/
      if clean_line.include?('init')
        clean_line.match(/init\w*/)[0] rescue 'init'
      else
        clean_line.match(/func\s+(\w+)/)[1] rescue ''
      end
    when /^@available/
      # Look at next line
      next_line = lines[1]&.strip || ''
      if next_line.match(/(?:class|struct|protocol|enum)\s+(\w+)/)
        $1
      elsif next_line.match(/func\s+(\w+)/)
        $1
      elsif next_line.match(/(?:let|var|weak)\s+(\w+)/)
        $1
      else
        ''
      end
    when /^#if/
      # Look at next line
      next_line = lines[1]&.strip || ''
      if next_line.match(/(?:class|struct|protocol|enum)\s+(\w+)/)
        $1
      elsif next_line.match(/func\s+(\w+)/)
        $1
      elsif next_line.match(/(?:let|var|weak)\s+(\w+)/)
        $1
      elsif next_line.match(/(?:init|convenience|required)/)
        'init'
      else
        ''
      end
    when /case\s+(\w+)/
      $1
    else
      clean_line.match(/\b(\w+)\b/)[1] rescue ''
    end
  end

  def determine_member_group
    # Group members for sorting within types
    # 1: Static properties
    # 2: Instance properties
    # 3: Initializers
    # 4: Static methods
    # 5: Instance methods
    # 6: Nested types
    # 0: Top-level

    return 0 if indent_level == 0

    declaration_line = lines.find { |line| line.strip.match?(/^(public|@objc|@available|#if|final|@_)/) }
    return 7 unless declaration_line

    clean_line = declaration_line.strip

    # Check in the actual content, not attributes
    actual_declaration = lines.find { |line| line.strip.match?(/^(public|@objc\s+public|final\s+public)/) }
    actual_declaration ||= lines.find { |line| line.strip.match?(/^(@available)/) && lines[lines.index(line) + 1] }

    if actual_declaration
      check_line = actual_declaration.strip
      # Look for static properties
      return 1 if check_line.match?(/static\s+(?:let|var)/)
      # Instance properties (including those in #if blocks)
      return 2 if check_line.match?(/^(?:@objc\s+)?public\s+(?:let|var|weak|unowned)/) ||
                  check_line.match?(/^#if/) && lines[lines.index(actual_declaration) + 1]&.match?(/(?:let|var|weak)/)
      # Initializers
      return 3 if check_line.match?(/init/) || check_line.match?(/^#if/) && lines[lines.index(actual_declaration) + 1]&.include?('init')
      # Static methods
      return 4 if check_line.match?(/static\s+func/)
      # Instance methods
      return 5 if check_line.match?(/func/)
      # Nested types
      return 6 if check_line.match?(/(?:class|struct|protocol|enum)\s+\w+/)
      # Enum cases
      return 2 if check_line.match?(/case\s+\w+/)
    end

    7
  end

  def add_line(line)
    @lines << line
  end

  def to_s(include_children = true)
    result = ''

    # Output all lines except closing brace
    lines.each do |line|
      if line.strip == '}'
        # Don't output closing brace yet
      else
        result += line
      end
    end

    # Output children
    if include_children
      children.each do |child|
        result += child.to_s(true)
      end
    end

    # Output closing brace if we had one
    closing_brace = lines.find { |line| line.strip == '}' }
    result += closing_brace if closing_brace

    result
  end
end

class SwiftInterfaceSorter
  def initialize(content)
    @content = content
    @root = SwiftInterfaceNode.new(-1)
  end

  def sort
    parse_content
    sort_nodes(@root)
    generate_output
  end

  private

  def parse_content
    lines = @content.lines
    stack = [@root]
    i = 0

    while i < lines.length
      line = lines[i]
      indent = line[/^[ \t]*/].length
      indent_level = indent / 2

      # Handle file-level imports, comments, blank lines
      if stack.length == 1 && (line.strip.start_with?('import ', '@_exported import', '//') || line.strip.empty?)
        @root.add_line(line)
        i += 1
        next
      end

      # Handle closing braces
      if line.strip == '}'
        stack[-1].add_line(line)
        stack.pop if stack.length > 1
        i += 1
        next
      end

      # Check if this is a compiler directive
      if line.strip.start_with?('#if')
        # This is a compiler directive - collect it and its contents
        node = SwiftInterfaceNode.new(indent_level)
        node.add_line(line) # Add #if line

        i += 1
        # Collect everything until #endif
        while i < lines.length && !lines[i].strip.start_with?('#endif')
          node.add_line(lines[i])
          i += 1
        end

        # Add #endif
        if i < lines.length
          node.add_line(lines[i])
          i += 1
        end

        node.finalize
        stack[-1].children << node
        next
      end

      # Check if this is a top-level or member declaration start
      is_declaration = line.strip.match?(/^(@available|@objc|@_\w+|public|extension|final\s+public|@frozen)/)

      # For members inside containers, also check indentation
      if stack.length > 1 && !is_declaration
        # This is a continuation line (like 'get' or body content)
        stack[-1].add_line(line)
        i += 1
        next
      end

      if is_declaration
        # Start a new declaration node
        node = SwiftInterfaceNode.new(indent_level)
        node.add_line(line)

        # Check if this line has an opening brace
        if line.include?('{')
          if line.strip.end_with?('}')
            # Single-line block
            node.finalize
            stack[-1].children << node
          else
            # Multi-line block
            node.finalize
            stack[-1].children << node
            stack << node
          end
          i += 1
        else
          # Multi-line declaration header - collect continuation lines
          i += 1
          while i < lines.length
            next_line = lines[i]
            next_indent = next_line[/^[ \t]*/].length / 2

            # If we hit a closing brace, we're done
            if next_line.strip == '}'
              break
            end

            # If indentation decreased or same level with new declaration, we're done
            if next_indent <= indent_level && next_line.strip.match?(/^(@available|@objc|@_\w+|public|extension|final\s+public)/)
              break
            end

            # If this is not more indented, and is not a continuation pattern, we're done
            if next_indent == indent_level && !next_line.strip.match?(/^(@available|@objc)/)
              break
            end

            node.add_line(next_line)

            # Check for opening brace in continuation
            if next_line.include?('{')
              if next_line.strip.end_with?('}')
                # Single-line block
                node.finalize
                stack[-1].children << node
              else
                # Multi-line block
                node.finalize
                stack[-1].children << node
                stack << node
              end
              i += 1
              break
            end

            i += 1
          end

          # If we collected lines but no opening brace, it's a declaration without a body
          if node.lines.any? && !node.lines.any? { |l| l.include?('{') }
            node.finalize
            stack[-1].children << node
          end
        end
      else
        # Shouldn't reach here normally, but handle gracefully
        stack[-1].add_line(line)
        i += 1
      end
    end
  end

  def sort_nodes(node)
    return if node.children.empty?

    # Sort children by group then by name
    node.children.sort_by! do |child|
      [child.member_group, child.sort_key.downcase]
    end

    # Recursively sort grandchildren
    node.children.each { |child| sort_nodes(child) }
  end

  def generate_output
    result = @root.lines.join

    @root.children.each do |child|
      result += child.to_s(true)
    end

    result
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  if ARGV.length != 2
    puts "Usage: ruby sort_swift_interface.rb <input_file> <output_file>"
    exit 1
  end

  input_file = ARGV[0]
  output_file = ARGV[1]

  unless File.exist?(input_file)
    puts "Error: Input file '#{input_file}' does not exist"
    exit 1
  end

  content = File.read(input_file)
  sorter = SwiftInterfaceSorter.new(content)
  sorted_content = sorter.sort

  File.write(output_file, sorted_content)
  puts "Sorted Swift interface written to #{output_file}"
end
