require 'net/http'
require 'json'
require 'uri'

# get the current working directory
current_dir = Dir.pwd

# use 'git rev-parse --show-toplevel' to get the git root directory
repo_path = `git -C #{current_dir} rev-parse --show-toplevel`.strip

def api_get_request(endpoint, token)
  uri = URI(endpoint)
  req = Net::HTTP::Get.new(uri)
  req['X-Api-Token'] = token

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end

  JSON.parse(res.body)
end

def get_added_strings(repo_path)
  new_strings = {}
  Dir.chdir(repo_path) do
    strings_files = `git diff --name-only master...`.split("\n").select { |f| f.end_with?(".strings") }
    strings_files.each do |file|
      added_lines = `git diff master... -- #{file}`.split("\n").select do |line| 
        line.start_with?('+') && !line.start_with?('+++') && line.include?('=') && !line.match(/^\/\//) 
      end
      new_strings[file] = added_lines.map do |line| 
        line.delete_prefix('+').strip.split('=')[0].gsub(/\"/, '').strip
      end 
    end
  end

  new_strings
end

def check_lokalise_translations(api_token, project_id, new_added_strings)
  keys = api_get_request("https://api.lokalise.com/api2/projects/#{project_id}/keys", api_token)

  all_keys_exist = true

  new_added_strings.each do |file_path, new_strings|
    puts "Checking translation for file #{file_path}"
    new_strings.each do |str|
      key = keys['keys'].find { |k| k['key_name']['other'] == str }
      if key
        translated_count = key['platforms']['ios']['is_translated']
        if translated_count
          puts "Translation for '#{str}' exists."
        else
          puts "Translation for '#{str}' does not exist."
          all_keys_exist = false
        end
      else
        puts "Key '#{str}' does not exist."
        all_keys_exist = false
      end
    end
  end

  exit 1 unless all_keys_exist
end

puts "Checking for any untranslated strings..."
new_strings_added = get_added_strings(repo_path)
puts(new_strings_added)
check_lokalise_translations(ENV['LOKALISE_API_KEY'], '747824695e51bc2f4aa912.89576472', new_strings_added)
puts "Done!"
