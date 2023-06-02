# swift_tests_extractor.rb  
  
require 'find'  
require 'json'  
  
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
  
  Find.find("./Example/PaymentSheet Example/PaymentSheetUITest") do |path|  
    swift_files << path if path.end_with?('.swift')  
  end  
  
  swift_files.each do |file|  
    classes = extract_test_classes(file)  
    test_classes.concat(classes)  
  end  
  
  skipped_tests1 = read_skipped_tests("./Example/PaymentSheet Example/PaymentSheet Example-Shard1.xctestplan")  
  skipped_tests2 = read_skipped_tests("./Example/PaymentSheet Example/PaymentSheet Example-Shard2.xctestplan")  
  all_skipped_tests = skipped_tests1 + skipped_tests2  
  
  exitcode = 0
  test_classes.each do |test_class|  
    if !all_skipped_tests.include?(test_class)  
      puts "#{test_class} is duplicated across test plans. Please remove it from PaymentSheet Example-Shard1.xctestplan or PaymentSheet Example-Shard2.xctestplan."  
      exitcode = 1
    end  
  end  
  exit(exitcode)
end  
  
main  