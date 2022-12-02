//
//  STPFileTest.m
//  Stripe
//
//  Created by Charles Scalesse on 1/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;



#import "STPTestUtils.h"

@interface STPFile ()

+ (STPFilePurpose)purposeFromString:(NSString *)string;

@end

@interface STPFileTest : XCTestCase

@end

@implementation STPFileTest

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
    STPFile *file1 = [STPFile decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"FileUpload"]];
    STPFile *file2 = [STPFile decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"FileUpload"]];

    XCTAssertNotEqual(file1, file2);

    XCTAssertEqualObjects(file1, file1);
    XCTAssertEqualObjects(file1, file2);

    XCTAssertEqual(file1.hash, file1.hash);
    XCTAssertEqual(file1.hash, file2.hash);
}

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[
                                            @"id",
                                            @"created",
                                            @"size",
                                            @"purpose",
                                            @"type",
                                            ];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:@"FileUpload"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPFile decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPFile decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"FileUpload"]]);
}

- (void)testInitializingFileWithAttributeDictionary {
    NSDictionary *response = [STPTestUtils jsonNamed:@"FileUpload"];
    STPFile *file = [STPFile decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(file.fileId, @"file_1AZl0o2eZvKYlo2CoIkwLzfd");
    XCTAssertEqualObjects(file.created, [NSDate dateWithTimeIntervalSince1970:1498674938]);
    XCTAssertEqual(file.purpose, STPFilePurposeDisputeEvidence);
    XCTAssertEqualObjects(file.size, @34478);
    XCTAssertEqualObjects(file.type, @"jpg");

    XCTAssertNotEqual(file.allResponseFields, response);
    XCTAssertEqualObjects(file.allResponseFields, response);
}

@end
