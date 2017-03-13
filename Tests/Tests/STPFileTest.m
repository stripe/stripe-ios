//
//  STPFileTest.m
//  Stripe
//
//  Created by Charles Scalesse on 1/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPFile.h"

@interface STPFileTest : XCTestCase

@property (nonatomic) STPFile *file;

@end

@implementation STPFileTest

- (void)setUp {
    _file = [[STPFile alloc] init];
}

- (NSDictionary *)completeAttributeDictionary {
    return @{
        @"id": @"file_something",
        @"created": @1483888528,
        @"size": @322035,
        @"type": @"png",
        @"purpose": @"identity_document",
    };
}

#pragma mark - Initialization Tests

- (void)testInitializingFileWithAttributeDictionary {
    NSMutableDictionary *apiResponse = [[self completeAttributeDictionary] mutableCopy];
    apiResponse[@"foo"] = @"bar";
    apiResponse[@"nested"] = @{@"baz": @"bang"};
    STPFile *fileWithAttributes = [STPFile decodedObjectFromAPIResponse:apiResponse];
    
    XCTAssertEqualObjects([fileWithAttributes fileId], @"file_something", @"fileId is set correctly");
    XCTAssertEqualObjects([fileWithAttributes created], [NSDate dateWithTimeIntervalSince1970:1483888528], @"created is set correctly");
    XCTAssertEqualObjects([fileWithAttributes size], @322035, @"size is set correctly");
    XCTAssertEqualObjects([fileWithAttributes type], @"png", @"type is set correctly");
    XCTAssertEqual(fileWithAttributes.purpose, STPFilePurposeIdentityDocument);
    
    NSDictionary *allResponseFields = fileWithAttributes.allResponseFields;
    XCTAssertEqual(allResponseFields[@"foo"], @"bar");
    XCTAssertEqual(allResponseFields[@"id"], @"file_something");
    XCTAssertEqualObjects(allResponseFields[@"nested"], @{@"baz": @"bang"});
    XCTAssertNil(allResponseFields[@"baz"]);
}

- (void)testInitializingFileFailsWhenMissingRequiredParam {
    NSMutableDictionary *apiResponse = [[self completeAttributeDictionary] mutableCopy];
    apiResponse[@"id"] = nil;
    STPFile *fileWithAttributes = [STPFile decodedObjectFromAPIResponse:apiResponse];
    XCTAssertNil(fileWithAttributes);
}

#pragma mark - Equality Tests

- (void)testFileEquals {
    STPFile *file1 = [STPFile decodedObjectFromAPIResponse:[self completeAttributeDictionary]];
    STPFile *file2 = [STPFile decodedObjectFromAPIResponse:[self completeAttributeDictionary]];
    
    XCTAssertEqualObjects(file1, file1, @"file should equal itself");
    XCTAssertEqualObjects(file1, file2, @"file with equal data should be equal");
}

@end
