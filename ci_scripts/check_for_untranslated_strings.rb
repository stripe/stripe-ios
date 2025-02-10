require 'net/http'
require 'json'
require 'uri'

$SCRIPT_DIR = __dir__
$ROOT_DIR = File.expand_path('..', $SCRIPT_DIR)

def api_get_request(endpoint, token)
  uri = URI(endpoint)
  req = Net::HTTP::Get.new(uri)
  req['X-Api-Token'] = token

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end

  JSON.parse(res.body)
end

def get_added_strings(current_dir)
  new_strings = {}

  strings_files = `git diff --name-only origin/master...`.split("\n").select { |f| f.end_with?(".strings") }

  strings_files.each do |file|
    added_lines = `git diff origin/master... -- #{file}`.split("\n").select do |line|
      line.start_with?('+') && !line.start_with?('+++') && line.include?('=') && !line.match(/^\/\//)
    end

    new_strings[file] = added_lines.map do |line|
      clean_line = line.delete_prefix('+').strip
      # Collect all positions of '=' in the line.
      eq_positions = []
      clean_line.enum_for(:scan, /=/).each do
        eq_positions << Regexp.last_match.begin(0)
      end

      # If for some reason there's no '=' at all, skip
      next if eq_positions.empty?

      # Grab the middle '=' index
      middle_eq_index = eq_positions[eq_positions.size / 2]

      # Everything before the middle '=' is the key
      key_part = clean_line[0...middle_eq_index].gsub(/\"/, '').strip

      key_part
    end.compact
  end

  new_strings
end

def check_lokalise_translations(api_token, project_id, new_added_strings)
  keys = api_get_request("https://api.lokalise.com/api2/projects/#{project_id}/keys?limit=5000&include_translations=1", api_token)
  missing_translations = []

  new_added_strings.each do |file_path, new_strings|
    puts "Checking translation for file #{file_path}"

    new_strings.each do |str|
      key = keys['keys'].find { |k| normalize_string(k['key_name']['ios']) == normalize_string(str) }

      if key
        translated_count = key['translations'].count { |t| !t['translation'].empty? }
        if translated_count > 30
          puts "Translations for '#{str}' exists."
        else
          puts "Translations for '#{str}' do not exist."
          missing_translations << str
        end
      else
        puts "String '#{str}' does not exist. Make sure you have uploaded your strings to Lokalise."
        missing_translations << str
      end
    end
  end

  missing_translations
end

def normalize_string(str)
  str.gsub(/[\\"]/, '')
end

new_strings_added = get_added_strings($ROOT_DIR)
missing_translations = check_lokalise_translations(ENV['LOKALISE_API_KEY'], '747824695e51bc2f4aa912.89576472', new_strings_added)
missing_translations = missing_translations.uniq
puts(missing_translations)
if missing_translations.any?
  File.open("missing_translations.txt", 'w') { |f| f.write missing_translations.join(", ") }
end
