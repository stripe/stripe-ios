#!/usr/bin/ruby
# This script checks the PaymentSheet test plans, ensuring every test class is
# enabled in exactly one shard.

require 'find'  
require 'json'  
  

$SCRIPT_DIR = __dir__
$ROOT_DIR = File.expand_path('..', $SCRIPT_DIR)

def extract_test_classes(file_path)  
  test_classes = []  
  
  File.open(file_path, "r").each_line do |line|  
    match = line.match(/class\s+(\w+)\s*:\s*(\w+(?:TestCase)?)/)  
    if match && match[2].end_with?("TestCase")  
      test_classes << match[1]  
    end 
  end  
  
  test_classes  
end  
  
def read_skipped_tests(json_file)  
  json_data = File.read(json_file)  
  data = JSON.parse(json_data)  
  
  skipped_tests = []  
  data['testTargets'].each do |test_target|  
    if test_target['skippedTests']  
      skipped_tests.concat(test_target['skippedTests'])  
    end  
  end  
  
  skipped_tests  
end  
  
def main  
  swift_files = []  
  test_classes = []  
  
  Find.find("#{$ROOT_DIR}/Example/PaymentSheet Example/PaymentSheetUITest") do |path|  
    swift_files << path if path.end_with?('.swift')  
  end  
  
  swift_files.each do |file|  
    classes = extract_test_classes(file)  
    test_classes.concat(classes)  
  end  
  
  shard_paths = Dir["#{$ROOT_DIR}/Example/PaymentSheet Example/PaymentSheet Example-Shard*.xctestplan"].sort
  all_skipped_tests = shard_paths.flat_map { |path| read_skipped_tests(path) }
  expected_skip_count = shard_paths.count - 1
  
  # Make sure every test in `test_classes` is skipped in one and only one of the test plans
  test_classes.each do |test_class|
    actual_skip_count = all_skipped_tests.count(test_class)
    if actual_skip_count != expected_skip_count
      puts "Test class #{test_class} is skipped in #{actual_skip_count}/#{shard_paths.count} test plans. It should be enabled in exactly one plan."
      puts "Please update the PaymentSheet Example-Shard test plans so the class is enabled in only one plan."
      exit(1)
    end
  end
end  
  
main
