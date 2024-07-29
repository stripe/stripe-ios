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
  skipped_tests3 = read_skipped_tests("#{$ROOT_DIR}/Example/PaymentSheet Example/PaymentSheet Example-Shard3.xctestplan")  
  skipped_tests4 = read_skipped_tests("#{$ROOT_DIR}/Example/PaymentSheet Example/PaymentSheet Example-Shard4.xctestplan")  

  all_skipped_tests = skipped_tests1 + skipped_tests2 + skipped_tests3 + skipped_tests4
  
  # Make sure every test in `test_classes` is skipped in one and only one of the test plans
  test_classes.each do |test_class|
    # Check against skipped_tests1 through 4 to make sure it appears three times
    if all_skipped_tests.count(test_class) != 3
      puts "Test class #{test_class} is skipped in #{all_skipped_tests.count(test_class)} test plans. It should be skipped in 3/4 test plans."
      puts "Please open \"PaymentSheet Example-Shard1.xctestplan\" through \"PaymentSheet Example-Shard4.xctestplan\" and ensure it is only enabled in one plan."
      exit(1)
    end
  end

  

end  
  
main  