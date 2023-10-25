#!/usr/bin/ruby
# This script checks the PaymentSheet test plans, ensuring all tests are skipped once across Shard1 and Shard2.

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
  
  skipped_tests1 = read_skipped_tests("#{$ROOT_DIR}/Example/PaymentSheet Example/PaymentSheet Example-Shard1.xctestplan")  
  skipped_tests2 = read_skipped_tests("#{$ROOT_DIR}/Example/PaymentSheet Example/PaymentSheet Example-Shard2.xctestplan")  
  
  # Make sure there are no duplicates across skipped_tests1 and 2
  skipped_in_both = skipped_tests1 & skipped_tests2
  if !skipped_in_both.empty?
    puts "#{skipped_in_both} skipped in both test plans. Remove one from the PaymentSheet Example-Shard1.xctestplan exclusion list."
    exit 1
  end

  all_skipped_tests = skipped_tests1 + skipped_tests2 
  
  exitcode = 0
  test_classes.each do |test_class|  
    puts "Checking #{test_class}"
    if !all_skipped_tests.include?(test_class)  
      puts "#{test_class} is duplicated across test plans. Please exclude it in PaymentSheet Example-Shard1.xctestplan or PaymentSheet Example-Shard2.xctestplan."  
      exitcode = 1
    end  
  end  
  exit(exitcode)
end  
  
main  