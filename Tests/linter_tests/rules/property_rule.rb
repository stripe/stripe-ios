require_relative '../utils/logger'

module Rules
  class PropertyRule
    def self.apply_rule(file_name, file_lines)
      file_lines = apply_property_spacing_rule(file_name, file_lines)
      file_lines = apply_property_attributes_ordering_rule(file_name, file_lines)

      file_lines
    end

    # Applies proper property definition spacing up to the type name
    #
    # Ex: `@property (nonatomic, strong) NSString *string;`
    #      ^                             ^
    def self.apply_property_spacing_rule(file_name, file_lines)
      file_lines_corrected = []

      file_lines.each_with_index do |line, idx|
        property = parse_property(line)

        if property.nil?
          # Do nothing
          file_lines_corrected << line
          next
        end

        # Determine correct spacing for property
        attributes_string = property[:attributes].join(', ')
        line_fixed = "@property (#{attributes_string}) #{property[:definition]}"

        if line == line_fixed
          # Do nothing
          file_lines_corrected << line
          next
        end

        # Generate corrected line and print info
        Utils::Logger.log_lint('Fix property spacing', file_name, idx + 1,
          line: line,
          line_fixed: line_fixed)

        file_lines_corrected << line_fixed
      end

      file_lines_corrected
    end

    # Applies proper property attribute ordering
    #
    # Ex:  `@property (strong, nonatomic) NSString *string;`
    #   => `@property (nonatomic, strong) NSString *string;`
    @ideal_ordering = %w[
      nonatomic
      atomic
      unsafe_unretained
      weak
      copy
      strong
      assign
      nonnull
      nullable
      null_resettable
      readonly
      readwrite
    ]
    def self.apply_property_attributes_ordering_rule(file_name, file_lines)
      file_lines_corrected = []

      file_lines.each_with_index do |line, idx|
        property = parse_property(line)

        if property.nil?
          # Do nothing
          file_lines_corrected << line
          next
        end

        # Determine correct ordering for given attributes
        attributes_actual = property[:attributes]
        attributes_ordered = []

        @ideal_ordering.each do |attr|
          attributes_ordered << attr if attributes_actual.include?(attr)
        end

        if attributes_actual.length != attributes_ordered.length
          Utils::Logger.log_error('Found attribute(s) missing from ideal_ordering list', line: line)
          raise RuntimeError
        end

        if attributes_actual == attributes_ordered
          # Do nothing
          file_lines_corrected << line
          next
        end

        # Generate corrected line and print info
        attributes_ordered_string = attributes_ordered.join(', ')

        line_fixed = "@property (#{attributes_ordered_string}) #{property[:definition]}"

        Utils::Logger.log_lint('Fix property attributes ordering', file_name, idx + 1,
          line: line,
          line_fixed: line_fixed,
          attributes_actual: attributes_actual,
          attributes_ordered: attributes_ordered)

        file_lines_corrected << line_fixed
      end

      file_lines_corrected
    end

    # Verifies that immutable classes with mutable counterparts are marked with copy
    @mutable_counterparts_list = %w[
      NSString
      NSArray
      NSDictionary
    ]
    def self.apply_property_copy_rule(file_name, file_lines)

    end

    # Parse property line into attributes and definition
    #
    # `@property (nonatomic, readwrite) NSString *type;  // Type of transaction`
    #   => {
    #        attributes: `[nonatomic, readwrite]`,
    #        definition: `NSString *type;  // Type of transaction`,
    #      }
    def self.parse_property(line)
      matches = /^@property\s*\(([\w,\s]+)\)\s*(.*)$/.match(line)

      if matches && matches.length == 3
        Utils::Logger.log_debug("Property matches: #{matches.inspect}")

        {
          attributes: matches[1].strip.split(/\s*,\s*/),
          definition: matches[2],
        }
      else
        if line.include?('@property')
          Utils::Logger.log_debug("Skipped property: #{line}")
        end

        nil
      end
    end
  end
end
