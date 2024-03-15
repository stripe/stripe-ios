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
      line.delete_prefix('+').strip.split('=')[0].gsub(/\"/, '').strip
    end
  end

  new_strings
end

def check_lokalise_translations(api_token, project_id, new_added_strings)
  keys = api_get_request("https://api.lokalise.com/api2/projects/#{project_id}/keys?limit=5000&include_translations=1", api_token)
  missing_translations = []

  new_added_strings.each do |file_path, new_strings|
    puts "Checking translation for file #{file_path}"

    new_strings.each do |str|
      key = keys['keys'].find { |k| k['key_name']['other'] == str }

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

new_strings_added = get_added_strings($ROOT_DIR)
missing_translations = check_lokalise_translations(ENV['LOKALISE_API_KEY'], '747824695e51bc2f4aa912.89576472', new_strings_added)
puts(missing_translations)
if missing_translations.any?
  File.open("missing_translations.txt", 'w') { |f| f.write missing_translations.join(", ") }
end
