require 'yaml'

module GetFrameworks
  def self.framework_names(file_path)
    begin
      # Read YAML data from file
      data = YAML.load(File.read(file_path))

      # Extract 'framework_name' from each module
      framework_names = data['modules'].map { |m| m['framework_name'] }.compact

      # Return framework_names
      return framework_names
    rescue StandardError => e
      # In case of an error, output it to the console
      puts "An error occurred getting framework names from modules.yaml: #{e.inspect}"
      return nil
    end
  end
end