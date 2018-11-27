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
@property (nonatomic) NSString *testProperty;
@property (nonatomic) NSString *testIgnoredProperty;
@property (nonatomic) NSArray *testArrayProperty;
@property (nonatomic) NSDictionary *testDictionaryProperty;
@property (nonatomic) STPTestFormEncodableObject *testNestedObjectProperty;
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
    NSDictionary *dictionary = [STPFormEncoder dictionaryForObject:object];
    return [STPFormEncoder queryStringFromParameters:dictionary];
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
    XCTAssertEqualObjects([self encodeObject:testObject], @"test_object[test_array_property][0]=1&test_object[test_array_property][1]=2&test_object[test_array_property][2]=3&test_object[test_property]=success");
}

- (void)testFormEncoding_BoolAndNumbers {
    STPTestFormEncodableObject *testObject = [STPTestFormEncodableObject new];
    testObject.testArrayProperty = @[@0,
                                     @1,
                                     [NSNumber numberWithBool:NO],
                                     [[NSNumber alloc] initWithBool:YES],
                                     @YES];
    XCTAssertEqualObjects([self encodeObject:testObject],
                          @"test_object[test_array_property][0]=0"
                          "&test_object[test_array_property][1]=1"
                          "&test_object[test_array_property][2]=false"
                          "&test_object[test_array_property][3]=true"
                          "&test_object[test_array_property][4]=true");
}

- (void)testFormEncoding_arrayOfEncodable {
    STPTestFormEncodableObject *testObject = [STPTestFormEncodableObject new];

    STPTestFormEncodableObject *inner1 = [STPTestFormEncodableObject new];
    inner1.testProperty = @"inner1";
    STPTestFormEncodableObject *inner2 = [STPTestFormEncodableObject new];
    inner2.testArrayProperty = @[@"inner2"];

    testObject.testArrayProperty = @[inner1, inner2];

    XCTAssertEqualObjects([self encodeObject:testObject],
                          @"test_object[test_array_property][0][test_property]=inner1"
                          "&test_object[test_array_property][1][test_array_property][0]=inner2");
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

- (void)testFormEncoding_dictionaryOfEncodable {
    STPTestFormEncodableObject *testObject = [STPTestFormEncodableObject new];

    STPTestFormEncodableObject *inner1 = [STPTestFormEncodableObject new];
    inner1.testProperty = @"inner1";
    STPTestFormEncodableObject *inner2 = [STPTestFormEncodableObject new];
    inner2.testArrayProperty = @[@"inner2"];

    testObject.testDictionaryProperty = @{@"one": inner1, @"two": inner2};

    XCTAssertEqualObjects([self encodeObject:testObject],
                          @"test_object[test_dictionary_property][one][test_property]=inner1"
                          "&test_object[test_dictionary_property][two][test_array_property][0]=inner2");
}

- (void)testFormEncoding_setOfEncodable {
    STPTestFormEncodableObject *testObject = [STPTestFormEncodableObject new];

    STPTestFormEncodableObject *inner = [STPTestFormEncodableObject new];
    inner.testProperty = @"inner";

    testObject.testArrayProperty = @[[NSSet setWithObject:inner]];

    XCTAssertEqualObjects([self encodeObject:testObject],
                          @"test_object[test_array_property][0][test_property]=inner");
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

- (void)testQueryStringWithBadFields {
    NSDictionary *params = @{
                             @"foo]": @"bar",
                             @"baz": @"qux[",
                             @"woo;": @";hoo",
                             };
    NSString *result = [STPFormEncoder queryStringFromParameters:params];
    XCTAssertEqualObjects(result, @"baz=qux%5B&foo%5D=bar&woo%3B=%3Bhoo");
}

- (void)testQueryStringFromParameters {
    NSDictionary *params = @{
                             @"foo": @"bar",
                             @"baz": @{
                                     @"qux": @1
                                     }
                             };
    NSString *result = [STPFormEncoder queryStringFromParameters:params];
    XCTAssertEqualObjects(result, @"baz[qux]=1&foo=bar");
}

- (void)testQueryStringFromNil {
    NSDictionary *obj = nil;
    NSString *result = [STPFormEncoder queryStringFromParameters:obj];
    XCTAssertEqualObjects(result, @"");
}

- (void)testPushProvisioningQueryStringFromParameters {
    NSDictionary *params = @{
                             @"ios": @{
                                     @"certificates": @[@"cert1", @"cert2"],
                                     @"nonce": @"123mynonce",
                                     @"nonce_signature": @"sig",
                                     },
                             };
    NSString *result = [STPFormEncoder queryStringFromParameters:params];
    XCTAssertEqualObjects(result, @"ios[certificates][0]=cert1&ios[certificates][1]=cert2&ios[nonce]=123mynonce&ios[nonce_signature]=sig");
}

@end
