require 'yaml'

module GetFrameworks
  def self.framework_names(file_path)
    data = YAML.safe_load(File.read(file_path))
    names = data.fetch('modules').map { |entry| entry.fetch('framework_name') }
    unless !names.empty? && names.uniq == names && names.all? { |name| name.is_a?(String) && name.match?(/\A[A-Za-z_][A-Za-z0-9_]*\z/) }
      raise "Invalid framework names in #{file_path}"
    end
    names
  end
end
