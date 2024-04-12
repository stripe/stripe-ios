require 'open3'

def diff(old_path, new_path)
  stdout, _stderr, _status = Open3.capture3("diff", "-u", old_path, new_path)

  stdout.lines.map do |line|
    case line[0..1]
    when "+ " then "+ #{line[2..-1].strip}"
    when "- " then "- #{line[2..-1].strip}"
    else nil
    end
  end.compact.join("\n")
end

if ARGV.length < 2
  puts "Please provide two files to diff."
  exit
end

diff_result = diff(ARGV[0], ARGV[1])

if !diff_result.empty?
  File.open("diff_result.txt", 'w') { |f| f.write diff_result }
end