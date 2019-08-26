//
//  STPBankBrandTest.m
//  StripeiOS Tests
//
//  Created by David Estes on 8/26/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPBankBrand.h"

@interface STPBankBrandTest : XCTestCase

@end

@implementation STPBankBrandTest

- (void)testStringFromBrand {
    NSArray<NSNumber *> *brands = @[
                                    @(STPBankBrandAffinBank),
                                    @(STPBankBrandAllianceBank),
                                    @(STPBankBrandAmbank),
                                    @(STPBankBrandBankIslam),
                                    @(STPBankBrandBankMuamalat),
                                    @(STPBankBrandBankRakyat),
                                    @(STPBankBrandBsn),
                                    @(STPBankBrandCimb),
                                    @(STPBankBrandHongLeongBank),
                                    @(STPBankBrandHsbc),
                                    @(STPBankBrandKfh),
                                    @(STPBankBrandMaybank2E),
                                    @(STPBankBrandMaybank2U),
                                    @(STPBankBrandOcbc),
                                    @(STPBankBrandPublicBank),
                                    @(STPBankBrandCimb),
                                    @(STPBankBrandRhb),
                                    @(STPBankBrandStandardChartered),
                                    @(STPBankBrandUob),
                                    @(STPBankBrandUnknown),
                                    ];

    for (NSNumber *brandNumber in brands) {
        STPBankBrand brand = [brandNumber integerValue];
        NSString *brandName = STPStringFromBankBrand(brand);
        NSString *brandID = STPIdentifierFromBankBrand(brand);
        STPBankBrand reverseTransformedBrand = STPBankBrandFromIdentifier(brandID);
        XCTAssertEqual(reverseTransformedBrand, brand);

        switch (brand) {
            case STPBankBrandAffinBank:
                XCTAssertEqualObjects(brandID, @"affin_bank");
                XCTAssertEqualObjects(brandName, @"Affin Bank");
                break;
            case STPBankBrandAllianceBank:
                XCTAssertEqualObjects(brandID, @"alliance_bank");
                XCTAssertEqualObjects(brandName, @"Alliance Bank");
                break;
            case STPBankBrandAmbank:
                XCTAssertEqualObjects(brandID, @"ambank");
                XCTAssertEqualObjects(brandName, @"AmBank");
                break;
            case STPBankBrandBankIslam:
                XCTAssertEqualObjects(brandID, @"bank_islam");
                XCTAssertEqualObjects(brandName, @"Bank Islam");
                break;
            case STPBankBrandBankMuamalat:
                XCTAssertEqualObjects(brandID, @"bank_muamalat");
                XCTAssertEqualObjects(brandName, @"Bank Muamalat");
                break;
            case STPBankBrandBankRakyat:
                XCTAssertEqualObjects(brandID, @"bank_rakyat");
                XCTAssertEqualObjects(brandName, @"Bank Rakyat");
                break;
            case STPBankBrandBsn:
                XCTAssertEqualObjects(brandID, @"bsn");
                XCTAssertEqualObjects(brandName, @"BSN");
                break;
            case STPBankBrandCimb:
                XCTAssertEqualObjects(brandID, @"cimb");
                XCTAssertEqualObjects(brandName, @"CIMB Clicks");
                break;
            case STPBankBrandHongLeongBank:
                XCTAssertEqualObjects(brandID, @"hong_leong_bank");
                XCTAssertEqualObjects(brandName, @"Hong Leong Bank");
                break;
            case STPBankBrandHsbc:
                XCTAssertEqualObjects(brandID, @"hsbc");
                XCTAssertEqualObjects(brandName, @"HSBC BANK");
                break;
            case STPBankBrandKfh:
                XCTAssertEqualObjects(brandID, @"kfh");
                XCTAssertEqualObjects(brandName, @"KFH");
                break;
            case STPBankBrandMaybank2E:
                XCTAssertEqualObjects(brandID, @"maybank2e");
                XCTAssertEqualObjects(brandName, @"Maybank2E");
                break;
            case STPBankBrandMaybank2U:
                XCTAssertEqualObjects(brandID, @"maybank2u");
                XCTAssertEqualObjects(brandName, @"Maybank2U");
                break;
            case STPBankBrandOcbc:
                XCTAssertEqualObjects(brandID, @"ocbc");
                XCTAssertEqualObjects(brandName, @"OCBC Bank");
                break;
            case STPBankBrandPublicBank:
                XCTAssertEqualObjects(brandID, @"public_bank");
                XCTAssertEqualObjects(brandName, @"Public Bank");
                break;
            case STPBankBrandRhb:
                XCTAssertEqualObjects(brandID, @"rhb");
                XCTAssertEqualObjects(brandName, @"RHB Bank");
                break;
            case STPBankBrandStandardChartered:
                XCTAssertEqualObjects(brandID, @"standard_chartered");
                XCTAssertEqualObjects(brandName, @"Standard Chartered");
                break;
            case STPBankBrandUob:
                XCTAssertEqualObjects(brandID, @"uob");
                XCTAssertEqualObjects(brandName, @"UOB Bank");
                break;
            case STPBankBrandUnknown:
                XCTAssertEqualObjects(brandID, @"unknown");
                XCTAssertEqualObjects(brandName, @"Unknown");
                break;
        }
    };
}

@end
