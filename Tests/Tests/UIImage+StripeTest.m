//
//  UIImage+StripeTest.m
//  Stripe
//
//  Created by Ben Guo on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIImage+Stripe.h"

@interface UIImage_StripeTest : XCTestCase
@property NSArray<NSNumber *> *cardBrands;
@end

@implementation UIImage_StripeTest

- (void)setUp {
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
    image = [UIImage stp_amexCardImage];
    XCTAssertNotNil(image);
    image = [UIImage stp_dinersClubCardImage];
    XCTAssertNotNil(image);
    image = [UIImage stp_discoverCardImage];
    XCTAssertNotNil(image);
    image = [UIImage stp_jcbCardImage];
    XCTAssertNotNil(image);
    image = [UIImage stp_masterCardCardImage];
    XCTAssertNotNil(image);
    image = [UIImage stp_visaCardImage];
    XCTAssertNotNil(image);
    image = [UIImage stp_unknownCardCardImage];
    XCTAssertNotNil(image);
}

- (void)testBrandImageForCardBrand {
    for (NSNumber *brand in self.cardBrands) {
        UIImage *image = [UIImage stp_brandImageForCardBrand:[brand integerValue]];
        XCTAssertNotNil(image);
    }
}

- (void)testCVCImageForCardBrand {
    for (NSNumber *brand in self.cardBrands) {
        UIImage *image = [UIImage stp_cvcImageForCardBrand:[brand integerValue]];
        XCTAssertNotNil(image);
    }
}

@end
