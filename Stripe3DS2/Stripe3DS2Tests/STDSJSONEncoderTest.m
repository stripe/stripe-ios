//
//  STDSJSONEncoderTest.m
//  Stripe3DS2Tests
//
//  Created by Yuki Tokuhiro on 3/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSJSONEncoder.h"

#pragma mark - STDSJSONEncodableObject

@interface STDSJSONEncodableObject : NSObject <STDSJSONEncodable>
@property (nonatomic, copy) NSString *testProperty;
@property (nonatomic, copy) NSArray *testArrayProperty;
@property (nonatomic, copy) NSDictionary *testDictionaryProperty;
@property (nonatomic) STDSJSONEncodableObject *testNestedObjectProperty;
@end

@implementation STDSJSONEncodableObject

+ (NSDictionary *)propertyNamesToJSONKeysMapping {
    return @{
             NSStringFromSelector(@selector(testProperty)): @"test_property",
             NSStringFromSelector(@selector(testArrayProperty)): @"test_array_property",
             NSStringFromSelector(@selector(testDictionaryProperty)): @"test_dictionary_property",
             NSStringFromSelector(@selector(testNestedObjectProperty)): @"test_nested_property",
             };
}

@end

#pragma mark - STDSJSONEncoderTest

@interface STDSJSONEncoderTest : XCTestCase
@end

@implementation STDSJSONEncoderTest

- (void)testEmptyEncodableObject {
    STDSJSONEncodableObject *object = [STDSJSONEncodableObject new];
    XCTAssertEqualObjects([STDSJSONEncoder dictionaryForObject:object], @{});
}

- (void)testNestedObject {
    STDSJSONEncodableObject *object = [STDSJSONEncodableObject new];
    STDSJSONEncodableObject *nestedObject = [STDSJSONEncodableObject new];
    nestedObject.testProperty = @"nested_object_property";
    object.testProperty = @"object_property";
    object.testNestedObjectProperty = nestedObject;
    NSDictionary *jsonDictionary = [STDSJSONEncoder dictionaryForObject:object];
    NSDictionary *expected = @{
                               @"test_property": @"object_property",
                               @"test_nested_property": @{
                                       @"test_property": @"nested_object_property",
                                       }
                               };
    XCTAssertEqualObjects(jsonDictionary, expected);
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:jsonDictionary]);
}

- (void)testSerializeDeserialize {
    STDSJSONEncodableObject *object = [STDSJSONEncodableObject new];
    object.testProperty = @"test";
    NSDictionary *expected = @{@"test_property": @"test"};
    NSData *data = [NSJSONSerialization dataWithJSONObject:[STDSJSONEncoder dictionaryForObject:object] options:0 error:nil];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    XCTAssertEqualObjects(expected, jsonObject);
}

- (void)testBoolAndNumbers {
    STDSJSONEncodableObject *testObject = [STDSJSONEncodableObject new];
    testObject.testArrayProperty = @[@0,
                                     @1,
                                     [NSNumber numberWithBool:NO],
                                     [[NSNumber alloc] initWithBool:YES],
                                     @YES];
    NSDictionary *jsonDictionary = [STDSJSONEncoder dictionaryForObject:testObject];
    NSDictionary *expected = @{
                               @"test_array_property": @[
                                       @0,
                                       @1,
                                       [NSNumber numberWithBool:NO],
                                       [[NSNumber alloc] initWithBool:YES],
                                       @YES],
                               };
    XCTAssertEqualObjects(jsonDictionary, expected);
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:jsonDictionary]);
    
}

#pragma mark NSArray

- (void)testArrayValueEmpty {
    STDSJSONEncodableObject *testObject = [STDSJSONEncodableObject new];
    testObject.testProperty = @"success";
    testObject.testArrayProperty = @[];
    NSDictionary *jsonDictionary = [STDSJSONEncoder dictionaryForObject:testObject];
    NSDictionary *expected = @{
                               @"test_property": @"success",
                               @"test_array_property": @[]
                               };
    XCTAssertEqualObjects(jsonDictionary, expected);
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:jsonDictionary]);
}

- (void)testArrayValue {
    STDSJSONEncodableObject *testObject = [STDSJSONEncodableObject new];
    testObject.testProperty = @"success";
    testObject.testArrayProperty = @[@1, @2, @3];
    NSDictionary *jsonDictionary = [STDSJSONEncoder dictionaryForObject:testObject];
    NSDictionary *expected = @{
                               @"test_property": @"success",
                               @"test_array_property": @[@1, @2, @3]
                               };
    XCTAssertEqualObjects(jsonDictionary, expected);
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:jsonDictionary]);

}

- (void)testArrayOfEncodable {
    STDSJSONEncodableObject *testObject = [STDSJSONEncodableObject new];

    STDSJSONEncodableObject *inner1 = [STDSJSONEncodableObject new];
    inner1.testProperty = @"inner1";
    STDSJSONEncodableObject *inner2 = [STDSJSONEncodableObject new];
    inner2.testArrayProperty = @[@"inner2"];

    testObject.testArrayProperty = @[inner1, inner2];
    NSDictionary *jsonDictionary = [STDSJSONEncoder dictionaryForObject:testObject];
    NSDictionary *expected = @{
                               @"test_array_property": @[
                                       @{
                                           @"test_property": @"inner1"
                                           },
                                       @{
                                           @"test_array_property": @[@"inner2"]
                                           }
                                       ]
                               };
    XCTAssertEqualObjects(jsonDictionary, expected);
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:jsonDictionary]);
}

#pragma mark NSDictionary

- (void)testDictionaryValueEmpty {
    STDSJSONEncodableObject *testObject = [STDSJSONEncodableObject new];
    testObject.testProperty = @"success";
    testObject.testDictionaryProperty = @{};
    NSDictionary *jsonDictionary = [STDSJSONEncoder dictionaryForObject:testObject];
    NSDictionary *expected = @{
                               @"test_property": @"success",
                               @"test_dictionary_property": @{}
                               };
    XCTAssertEqualObjects(jsonDictionary, expected);
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:jsonDictionary]);
}

- (void)testDictionaryValue {
    STDSJSONEncodableObject *testObject = [STDSJSONEncodableObject new];
    testObject.testProperty = @"success";
    testObject.testDictionaryProperty = @{@"foo": @"bar"};
    NSDictionary *jsonDictionary = [STDSJSONEncoder dictionaryForObject:testObject];
    NSDictionary *expected = @{
                               @"test_property": @"success",
                               @"test_dictionary_property": @{@"foo": @"bar"}
                               };
    XCTAssertEqualObjects(jsonDictionary, expected);
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:jsonDictionary]);

}

- (void)testDictionaryOfEncodable {
    STDSJSONEncodableObject *testObject = [STDSJSONEncodableObject new];

    STDSJSONEncodableObject *inner1 = [STDSJSONEncodableObject new];
    inner1.testProperty = @"inner1";
    STDSJSONEncodableObject *inner2 = [STDSJSONEncodableObject new];
    inner2.testArrayProperty = @[@"inner2"];

    testObject.testDictionaryProperty = @{@"one": inner1, @"two": inner2};

    NSDictionary *jsonDictionary = [STDSJSONEncoder dictionaryForObject:testObject];
    NSDictionary *expected = @{
                               @"test_dictionary_property": @{
                                       @"one": @{
                                               @"test_property": @"inner1"
                                               },
                                       @"two": @{
                                               @"test_array_property": @[@"inner2"]
                                               }
                                       }
                               };
    XCTAssertEqualObjects(jsonDictionary, expected);
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:jsonDictionary]);
}

@end
