//
//  STPFileFunctionalTest.m
//  Stripe
//
//  Created by Charles Scalesse on 1/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPFileClient.h"
#import "STPFile.h"

@interface STPFileFunctionalTest : XCTestCase
@end

@implementation STPFileFunctionalTest

- (void)testCreateFileForIdentityDocument {
    STPFileClient *client = [[STPFileClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"File creation for identity document"];
    
    UIImage *image = [UIImage imageNamed:@"license" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    
    [client uploadImage:image
                purpose:STPFilePurposeIdentityDocument
             completion:^(STPFile * _Nullable file, NSError * _Nullable error) {
                 [expectation fulfill];
                 XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
                 
                 XCTAssertNotNil(file.fileId);
                 XCTAssertNotNil(file.created);
                 XCTAssertEqual(file.purpose, STPFilePurposeIdentityDocument);
                 XCTAssertNotNil(file.size);
                 XCTAssertEqualObjects(@"jpg", file.type);
    }];
    
    [self waitForExpectationsWithTimeout:10.0f handler:nil];
}

- (void)testCreateFileForDisputeEvidence {
    STPFileClient *client = [[STPFileClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"File creation for dispute evidence"];
    
    UIImage *image = [UIImage imageNamed:@"license" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    
    [client uploadImage:image
                purpose:STPFilePurposeDisputeEvidence
             completion:^(STPFile * _Nullable file, NSError * _Nullable error) {
                 [expectation fulfill];
                 XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
                 
                 XCTAssertNotNil(file.fileId);
                 XCTAssertNotNil(file.created);
                 XCTAssertEqual(file.purpose, STPFilePurposeDisputeEvidence);
                 XCTAssertNotNil(file.size);
                 XCTAssertEqualObjects(@"jpg", file.type);
             }];
    
    [self waitForExpectationsWithTimeout:10.0f handler:nil];
}

- (void)testInvalidKey {
    STPFileClient *client = [[STPFileClient alloc] initWithPublishableKey:@"not_a_valid_key_asdf"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Bad file creation"];
    
    UIImage *image = [UIImage imageNamed:@"license" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    
    [client uploadImage:image
                 purpose:STPFilePurposeIdentityDocument
              completion:^(STPFile * _Nullable file, NSError * _Nullable error) {
                  [expectation fulfill];
                  XCTAssertNil(file, @"file should be nil");
                  XCTAssertNotNil(error, @"error should not be nil");
                  XCTAssert([error.localizedDescription rangeOfString:@"asdf"].location != NSNotFound, @"error should contain last 4 of key");
              }];
    
    [self waitForExpectationsWithTimeout:10.0f handler:nil];
}

@end
