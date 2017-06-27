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

@end

@implementation STPFileTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
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

    XCTAssertNotEqual(file1, file2);

    XCTAssertEqualObjects(file1, file1);
    XCTAssertEqualObjects(file1, file2);

    XCTAssertEqual(file1.hash, file1.hash);
    XCTAssertEqual(file1.hash, file2.hash);
}

#pragma mark - STPAPIResponseDecodable Tests

- (NSDictionary *)completeAttributeDictionary {
    // Source: https://stripe.com/docs/api#file_upload_object
    return @{
        @"id": @"file_1AXyapEOD54MuFwSnhlqqvsX",
        @"object": @"file_upload",
        @"created": @(1498250487),
        @"purpose": @"dispute_evidence",
        @"size": @9863,
        @"type": @"png",
        @"url": @"https://stripe-upload-api.s3.amazonaws.com/uploads/file_1AXyapEOD54MuFwSnhlqqvsX?AWSAccessKeyId=KEY_ID&Expires=TIMESTAMP&Signature=SIGNATURE"
    };
}

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[
                                            @"id",
                                            @"created",
                                            @"size",
                                            @"purpose",
                                            @"type",
                                            ];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[self completeAttributeDictionary] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPFile decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPFile decodedObjectFromAPIResponse:[self completeAttributeDictionary]]);
}

- (void)testInitializingFileWithAttributeDictionary {
    NSDictionary *response = [self completeAttributeDictionary];
    STPFile *file = [STPFile decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(file.fileId, @"file_1AXyapEOD54MuFwSnhlqqvsX");
    XCTAssertEqualObjects(file.created, [NSDate dateWithTimeIntervalSince1970:1498250487]);
    XCTAssertEqual(file.purpose, STPFilePurposeDisputeEvidence);
    XCTAssertEqualObjects(file.size, @9863);
    XCTAssertEqualObjects(file.type, @"png");

    XCTAssertNotEqual(file.allResponseFields, response);
    XCTAssertEqualObjects(file.allResponseFields, response);
}

@end
