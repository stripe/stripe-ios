//
//  STPCardBrandTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/3/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPCardBrand.h"

@interface STPCardBrandTest : XCTestCase

@end

@implementation STPCardBrandTest

- (void)testStringFromBrand {
    NSArray<NSNumber *> *brands = @[
                                    @(STPCardBrandAmex),
                                    @(STPCardBrandDinersClub),
                                    @(STPCardBrandDiscover),
                                    @(STPCardBrandJCB),
                                    @(STPCardBrandMasterCard),
                                    @(STPCardBrandUnionPay),
                                    @(STPCardBrandVisa),
                                    @(STPCardBrandUnknown),
                                    ];

    for (NSNumber *brandNumber in brands) {
        STPCardBrand brand = [brandNumber integerValue];
        NSString *string = STPStringFromCardBrand(brand);
        
        switch (brand) {
            case STPCardBrandAmex:
                XCTAssertEqualObjects(string, @"American Express");
                break;
            case STPCardBrandDinersClub:
                XCTAssertEqualObjects(string, @"Diners Club");
                break;
            case STPCardBrandDiscover:
                XCTAssertEqualObjects(string, @"Discover");
                break;
            case STPCardBrandJCB:
                XCTAssertEqualObjects(string, @"JCB");
                break;
            case STPCardBrandMasterCard:
                XCTAssertEqualObjects(string, @"MasterCard");
                break;
            case STPCardBrandUnionPay:
                XCTAssertEqualObjects(string, @"UnionPay");
                break;
            case STPCardBrandVisa:
                XCTAssertEqualObjects(string, @"Visa");
                break;
            case STPCardBrandUnknown:
                XCTAssertEqualObjects(string, @"Unknown");
                break;
        }
    };
}

@end
