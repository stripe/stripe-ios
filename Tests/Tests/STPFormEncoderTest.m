//
//  STPFormEncoderTest.m
//  Stripe Tests
//
//  Created by Jack Flintermann on 1/8/15.
//
//

@import XCTest;
#import "STPFormEncoder.h"
#import "STPFormEncodable.h"

@interface STPTestFormEncodableObject : NSObject<STPFormEncodable>
@property(nonatomic) NSString *testProperty;
@property(nonatomic) NSString *testIgnoredProperty;
@property(nonatomic) NSArray *testArrayProperty;
@property(nonatomic) NSDictionary *testDictionaryProperty;
@property(nonatomic) STPTestFormEncodableObject *testNestedObjectProperty;
@end

@implementation STPTestFormEncodableObject

@synthesize additionalAPIParameters;

+ (NSString *)rootObjectName {
    return @"test_object";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             @"testProperty": @"test_property",
             @"testArrayProperty": @"test_array_property",
             @"testDictionaryProperty": @"test_dictionary_property",
             @"testNestedObjectProperty": @"test_nested_property",
             };
}

@end

@interface STPTestNilRootObjectFormEncodableObject : STPTestFormEncodableObject
@end

@implementation STPTestNilRootObjectFormEncodableObject

+ (NSString *)rootObjectName {
    return nil;
}

@end

@interface STPFormEncoderTest : XCTestCase
@end

@implementation STPFormEncoderTest

- (void)testStringByReplacingSnakeCaseWithCamelCase {
    NSString *camelCase = [STPFormEncoder stringByReplacingSnakeCaseWithCamelCase:@"test_1_2_34_test"];
    XCTAssertEqualObjects(@"test1234Test", camelCase);
}

// helper test method
- (NSString *)encodeObject:(STPTestFormEncodableObject *)object {
    NSData *encoded = [STPFormEncoder formEncodedDataForObject:object];
    return [[[NSString alloc] initWithData:encoded encoding:NSUTF8StringEncoding] stringByRemovingPercentEncoding];
}

- (void)testFormEncoding_emptyObject {
    STPTestFormEncodableObject *testObject = [STPTestFormEncodableObject new];
    XCTAssertEqualObjects([self encodeObject:testObject], @"");
}

- (void)testFormEncoding_normalObject {
    STPTestFormEncodableObject *testObject = [STPTestFormEncodableObject new];
    testObject.testProperty = @"success";
    testObject.testIgnoredProperty = @"ignoreme";
    XCTAssertEqualObjects([self encodeObject:testObject], @"test_object[test_property]=success");
}

- (void)testFormEncoding_additionalAttributes {
    STPTestFormEncodableObject *testObject = [STPTestFormEncodableObject new];
    testObject.testProperty = @"success";
    testObject.additionalAPIParameters = @{@"foo": @"bar", @"nested": @{@"nested_key": @"nested_value"}};
    XCTAssertEqualObjects([self encodeObject:testObject], @"test_object[foo]=bar&test_object[nested][nested_key]=nested_value&test_object[test_property]=success");
}

- (void)testFormEncoding_arrayValue_empty {
    STPTestFormEncodableObject *testObject = [STPTestFormEncodableObject new];
    testObject.testProperty = @"success";
    testObject.testArrayProperty = @[];
    XCTAssertEqualObjects([self encodeObject:testObject], @"test_object[test_property]=success");
}

- (void)testFormEncoding_arrayValue {
    STPTestFormEncodableObject *testObject = [STPTestFormEncodableObject new];
    testObject.testProperty = @"success";
    testObject.testArrayProperty = @[@1, @2, @3];
    XCTAssertEqualObjects([self encodeObject:testObject], @"test_object[test_array_property][]=1&test_object[test_array_property][]=2&test_object[test_array_property][]=3&test_object[test_property]=success");
}

- (void)testFormEncoding_dictionaryValue_empty {
    STPTestFormEncodableObject *testObject = [STPTestFormEncodableObject new];
    testObject.testProperty = @"success";
    testObject.testDictionaryProperty = @{};
    XCTAssertEqualObjects([self encodeObject:testObject], @"test_object[test_property]=success");
}

- (void)testFormEncoding_dictionaryValue {
    STPTestFormEncodableObject *testObject = [STPTestFormEncodableObject new];
    testObject.testProperty = @"success";
    testObject.testDictionaryProperty = @{@"foo": @"bar"};
    XCTAssertEqualObjects([self encodeObject:testObject], @"test_object[test_dictionary_property][foo]=bar&test_object[test_property]=success");
}

- (void)testFormEncoding_nestedValue {
    STPTestFormEncodableObject *testObject1 = [STPTestFormEncodableObject new];
    STPTestFormEncodableObject *testObject2 = [STPTestFormEncodableObject new];
    testObject2.testProperty = @"nested_object";
    testObject1.testProperty = @"success";
    testObject1.testNestedObjectProperty = testObject2;
    XCTAssertEqualObjects([self encodeObject:testObject1], @"test_object[test_nested_property][test_property]=nested_object&test_object[test_property]=success");
}

- (void)testFormEncoding_nilRootObject {
    STPTestNilRootObjectFormEncodableObject *testObject = [STPTestNilRootObjectFormEncodableObject new];
    testObject.testProperty = @"success";
    XCTAssertEqualObjects([self encodeObject:testObject], @"test_property=success");
}

- (void)testQueryStringFromParameters {
    NSDictionary *params = @{
                             @"foo": @"bar",
                             @"baz": @{
                                     @"qux": @1
                                     }
                             };
    NSString *result = [STPFormEncoder queryStringFromParameters:params];
    XCTAssertEqualObjects(result, @"baz%5Bqux%5D=1&foo=bar");
}

@end
