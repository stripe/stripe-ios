//
//  STPBinRangeTest.m
//  Stripe
//
//  Created by Jack Flintermann on 5/24/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPBINRange.h"

@interface STPBINRange(Testing)

@property(nonatomic)NSUInteger length;
@property(nonatomic)NSString *qRangeLow;
@property(nonatomic)NSString *qRangeHigh;
@property(nonatomic)STPCardBrand brand;

- (BOOL)matchesNumber:(NSString *)number;

@end

@interface STPBinRangeTest : XCTestCase
@end

@implementation STPBinRangeTest

- (void)testAllRanges {
    for (STPBINRange *binRange in [STPBINRange allRanges]) {
        XCTAssertEqual(binRange.qRangeLow.length, binRange.qRangeHigh.length);
    }
}

- (void)testMatchesNumber {
    STPBINRange *binRange = [STPBINRange new];
    binRange.qRangeLow = @"134";
    binRange.qRangeHigh = @"167";
    
    XCTAssertFalse([binRange matchesNumber:@"0"]);
    XCTAssertFalse([binRange matchesNumber:@"1"]);
    XCTAssertFalse([binRange matchesNumber:@"2"]);
    
    XCTAssertFalse([binRange matchesNumber:@"133"]);
    XCTAssert([binRange matchesNumber:@"134"]);
    XCTAssert([binRange matchesNumber:@"135"]);
    XCTAssert([binRange matchesNumber:@"167"]);
    XCTAssertFalse([binRange matchesNumber:@"168"]);
    
    XCTAssertFalse([binRange matchesNumber:@"1244"]);
    XCTAssert([binRange matchesNumber:@"1340"]);
    XCTAssert([binRange matchesNumber:@"1344"]);
    XCTAssert([binRange matchesNumber:@"1444"]);
    XCTAssert([binRange matchesNumber:@"1670"]);
    XCTAssert([binRange matchesNumber:@"1679"]);
    XCTAssertFalse([binRange matchesNumber:@"1680"]);
    
    binRange.qRangeLow = @"";
    binRange.qRangeHigh = @"";
    XCTAssert([binRange matchesNumber:@""]);
    XCTAssert([binRange matchesNumber:@"1"]);
}

- (void)testBinRangesForNumber {
    NSArray<STPBINRange *> *binRanges;
    
    binRanges = [STPBINRange binRangesForNumber:@"4136000000008"];
    XCTAssertEqual(binRanges.count, 3U);
    
    binRanges = [STPBINRange binRangesForNumber:@"4242424242424242"];
    XCTAssertEqual(binRanges.count, 2U);
    
    binRanges = [STPBINRange binRangesForNumber:@"5555555555554444"];
    XCTAssertEqual(binRanges.count, 2U);
    
    binRanges = [STPBINRange binRangesForNumber:@""];
    XCTAssertEqual(binRanges.count, 1U);
    
    binRanges = [STPBINRange binRangesForNumber:@"123"];
    XCTAssertEqual(binRanges.count, 1U);
}

- (void)testBinRangesForBrand {
    NSArray *allBrands = @[@(STPCardBrandVisa),
                           @(STPCardBrandAmex),
                           @(STPCardBrandMasterCard),
                           @(STPCardBrandDiscover),
                           @(STPCardBrandJCB),
                           @(STPCardBrandDinersClub),
                           @(STPCardBrandUnknown)];
    for (NSNumber *brand in allBrands) {
        NSArray<STPBINRange *> *binRanges = [STPBINRange binRangesForBrand:brand.integerValue];
        for (STPBINRange *binRange in binRanges) {
            XCTAssertEqual(binRange.brand, brand.integerValue);
        }
    }
}

- (void)testMostSpecifiBinRangeForNumber {
    STPBINRange *binRange;
    
    binRange = [STPBINRange mostSpecificBINRangeForNumber:@""];
    XCTAssertEqual(binRange.brand, STPCardBrandUnknown);
    
    binRange = [STPBINRange mostSpecificBINRangeForNumber:@"4242424242422"];
    XCTAssertEqual(binRange.brand, STPCardBrandVisa);
    XCTAssertEqual(binRange.length, 16U);
    
    binRange = [STPBINRange mostSpecificBINRangeForNumber:@"4136000000008"];
    XCTAssertEqual(binRange.brand, STPCardBrandVisa);
    XCTAssertEqual(binRange.length, 13U);
    
    binRange = [STPBINRange mostSpecificBINRangeForNumber:@"4242424242424242"];
    XCTAssertEqual(binRange.brand, STPCardBrandVisa);
    XCTAssertEqual(binRange.length, 16U);
}

@end
