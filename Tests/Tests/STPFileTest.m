//
//  STPFileTest.m
//  Stripe
//
//  Created by Charles Scalesse on 1/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPFile.h"
#import "STPFile+Private.h"

@interface STPFileTest : XCTestCase

@property (nonatomic) STPFile *file;

@end

@implementation STPFileTest

- (void)setUp {
    _file = [[STPFile alloc] init];
}

#pragma mark - STPFilePurpose Tests

- (void)testPurposeFromString {
    XCTAssertEqual([STPFile purposeFromString:@"dispute_evidence"], STPFilePurposeDisputeEvidence);
    XCTAssertEqual([STPFile purposeFromString:@"DISPUTE_EVIDENCE"], STPFilePurposeDisputeEvidence);

    XCTAssertEqual([STPFile purposeFromString:@"identity_document"], STPFilePurposeIdentityDocument);
    XCTAssertEqual([STPFile purposeFromString:@"IDENTITY_DOCUMENT"], STPFilePurposeIdentityDocument);

    XCTAssertEqual([STPFile purposeFromString:@"unknown"], STPFilePurposeUnknown);
    XCTAssertEqual([STPFile purposeFromString:@"UNKNOWN"], STPFilePurposeUnknown);

    XCTAssertEqual([STPFile purposeFromString:@"garbage"], STPFilePurposeUnknown);
    XCTAssertEqual([STPFile purposeFromString:@"GARBAGE"], STPFilePurposeUnknown);
}

- (void)testStringFromPurpose {
    NSArray<NSNumber *> *values = @[
                                    @(STPFilePurposeDisputeEvidence),
                                    @(STPFilePurposeIdentityDocument),
                                    @(STPFilePurposeUnknown),
                                    ];

    for (NSNumber *purposeNumber in values) {
        STPFilePurpose purpose = (STPFilePurpose)[purposeNumber integerValue];
        NSString *string = [STPFile stringFromPurpose:purpose];

        switch (purpose) {
            case STPFilePurposeDisputeEvidence:
                XCTAssertEqualObjects(string, @"dispute_evidence");
                break;
            case STPFilePurposeIdentityDocument:
                XCTAssertEqualObjects(string, @"identity_document");
                break;
            case STPFilePurposeUnknown:
                XCTAssertNil(string);
                break;
        }
    }
}

#pragma mark - Equality Tests

- (void)testFileEquals {
    STPFile *file1 = [STPFile decodedObjectFromAPIResponse:[self completeAttributeDictionary]];
    STPFile *file2 = [STPFile decodedObjectFromAPIResponse:[self completeAttributeDictionary]];

    XCTAssertEqualObjects(file1, file1, @"file should equal itself");
    XCTAssertEqualObjects(file1, file2, @"file with equal data should be equal");
}

#pragma mark - STPAPIResponseDecodable Tests

- (NSDictionary *)completeAttributeDictionary {
    return @{
        @"id": @"file_something",
        @"created": @1483888528,
        @"size": @322035,
        @"type": @"png",
        @"purpose": @"identity_document",
    };
}

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

@end
