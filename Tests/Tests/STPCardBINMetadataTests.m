//
//  STPCardBINMetadata.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 7/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAPIClient+Private.h"
#import "STPBINRange.h"
#import "STPCardBINMetadata.h"
#import "STPTestingAPIClient.h"

@interface STPCardBINMetadataTests : XCTestCase

@end

@implementation STPCardBINMetadataTests

- (void)testAPICall {
    [[STPAPIClient sharedClient] setPublishableKey:STPTestingDefaultPublishableKey];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Retrieve card metadata"];
    
    [[STPAPIClient sharedClient] retrieveCardBINMetadataForPrefix:@"424242" withCompletion:^(STPCardBINMetadata * _Nullable cardMetadata, NSError * _Nullable error) {
        XCTAssertNotNil(cardMetadata);
        XCTAssertTrue(cardMetadata.ranges.count > 0);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:STPTestingNetworkRequestTimeout];
}

- (void)testLoadingInBINRange {
    [[STPAPIClient sharedClient] setPublishableKey:STPTestingDefaultPublishableKey];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Retrieve card metadata"];
    NSArray<STPBINRange *> *hardCodedBinRanges = [STPBINRange allRanges];
    [STPBINRange retrieveBINRangesForPrefix:@"424242" completion:^(NSArray<STPBINRange *> * _Nullable ranges, NSError * _Nullable error) {
        XCTAssertNotNil(ranges);
        XCTAssertNil(error);
        XCTAssertTrue(ranges.count > 0);
        XCTAssertTrue([STPBINRange allRanges].count == hardCodedBinRanges.count + ranges.count);
        for (STPBINRange *range in ranges) {
            XCTAssertTrue([[STPBINRange allRanges] containsObject:range]);
        }
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:STPTestingNetworkRequestTimeout];

}

@end
