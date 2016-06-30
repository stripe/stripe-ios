//
//  STPImageLibraryTest.m
//  Stripe
//
//  Created by Jack Flintermann on 6/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPCardBrand.h"
#import "STPImageLibrary.h"

@interface STPImageLibraryTest : XCTestCase
@property NSArray<NSNumber *> *cardBrands;
@end

@implementation STPImageLibraryTest

- (void)setUp {
    [super setUp];
    self.cardBrands = @[
                        @(STPCardBrandAmex),
                        @(STPCardBrandDinersClub),
                        @(STPCardBrandDiscover),
                        @(STPCardBrandJCB),
                        @(STPCardBrandMasterCard),
                        @(STPCardBrandUnknown),
                        @(STPCardBrandVisa),
                        ];
}
- (void)testCardIconMethods {
    UIImage *image = nil;
    image = [STPImageLibrary amexCardImage];
    XCTAssertNotNil(image);
    image = [STPImageLibrary dinersClubCardImage];
    XCTAssertNotNil(image);
    image = [STPImageLibrary discoverCardImage];
    XCTAssertNotNil(image);
    image = [STPImageLibrary jcbCardImage];
    XCTAssertNotNil(image);
    image = [STPImageLibrary masterCardCardImage];
    XCTAssertNotNil(image);
    image = [STPImageLibrary visaCardImage];
    XCTAssertNotNil(image);
    image = [STPImageLibrary unknownCardCardImage];
    XCTAssertNotNil(image);
}

- (void)testBrandImageForCardBrand {
    for (NSNumber *brand in self.cardBrands) {
        UIImage *image = [STPImageLibrary brandImageForCardBrand:[brand integerValue]];
        XCTAssertNotNil(image);
    }
}

- (void)testCVCImageForCardBrand {
    for (NSNumber *brand in self.cardBrands) {
        UIImage *image = [STPImageLibrary cvcImageForCardBrand:[brand integerValue]];
        XCTAssertNotNil(image);
    }
}

@end
