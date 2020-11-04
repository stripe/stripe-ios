//
//  STPFileFunctionalTest.m
//  Stripe
//
//  Created by Charles Scalesse on 1/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPTestingAPIClient.h"

@interface STPFileFunctionalTest : XCTestCase
@end

@implementation STPFileFunctionalTest


- (UIImage *)testImage {
return [UIImage imageNamed:@"stp_test_upload_image.jpeg"
                  inBundle:[NSBundle bundleForClass:self.class]
compatibleWithTraitCollection:nil];
}

- (void)testCreateFileForIdentityDocument {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"File creation for identity document"];
    
    UIImage *image = [self testImage];
    
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
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCreateFileForDisputeEvidence {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"File creation for dispute evidence"];
    
    UIImage *image = [self testImage];
    
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
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testInvalidKey {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"not_a_valid_key_asdf"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Bad file creation"];
    
    UIImage *image = [self testImage];
    
    [client uploadImage:image
                 purpose:STPFilePurposeIdentityDocument
              completion:^(STPFile * _Nullable file, NSError * _Nullable error) {
                  [expectation fulfill];
                  XCTAssertNil(file, @"file should be nil");
                  XCTAssertNotNil(error, @"error should not be nil");
                  XCTAssert([error.localizedDescription rangeOfString:@"asdf"].location != NSNotFound, @"error should contain last 4 of key");
              }];
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
