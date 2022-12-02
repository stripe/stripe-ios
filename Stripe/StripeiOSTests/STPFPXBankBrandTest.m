//
//  STPFPXBankBrandTest.m
//  StripeiOS Tests
//
//  Created by David Estes on 8/26/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>



@interface STPFPXBankBrandTest : XCTestCase

@end

@implementation STPFPXBankBrandTest

- (void)testStringFromBrand {
    NSArray<NSNumber *> *brands = @[
                                    @(STPFPXBankBrandAffinBank),
                                    @(STPFPXBankBrandAllianceBank),
                                    @(STPFPXBankBrandAmbank),
                                    @(STPFPXBankBrandBankIslam),
                                    @(STPFPXBankBrandBankMuamalat),
                                    @(STPFPXBankBrandBankRakyat),
                                    @(STPFPXBankBrandBSN),
                                    @(STPFPXBankBrandCIMB),
                                    @(STPFPXBankBrandHongLeongBank),
                                    @(STPFPXBankBrandHSBC),
                                    @(STPFPXBankBrandKFH),
                                    @(STPFPXBankBrandMaybank2E),
                                    @(STPFPXBankBrandMaybank2U),
                                    @(STPFPXBankBrandOcbc),
                                    @(STPFPXBankBrandPublicBank),
                                    @(STPFPXBankBrandCIMB),
                                    @(STPFPXBankBrandRHB),
                                    @(STPFPXBankBrandStandardChartered),
                                    @(STPFPXBankBrandUOB),
                                    @(STPFPXBankBrandUnknown),
                                    ];

    for (NSNumber *brandNumber in brands) {
        STPFPXBankBrand brand = [brandNumber integerValue];
        NSString *brandName = [STPFPXBank stringFrom:brand];
        NSString *brandID = [STPFPXBank identifierFrom:brand];
        STPFPXBankBrand reverseTransformedBrand = [STPFPXBank brandFrom:brandID];
        XCTAssertEqual(reverseTransformedBrand, brand);

        switch (brand) {
            case STPFPXBankBrandAffinBank:
                XCTAssertEqualObjects(brandID, @"affin_bank");
                XCTAssertEqualObjects(brandName, @"Affin Bank");
                break;
            case STPFPXBankBrandAllianceBank:
                XCTAssertEqualObjects(brandID, @"alliance_bank");
                XCTAssertEqualObjects(brandName, @"Alliance Bank");
                break;
            case STPFPXBankBrandAmbank:
                XCTAssertEqualObjects(brandID, @"ambank");
                XCTAssertEqualObjects(brandName, @"AmBank");
                break;
            case STPFPXBankBrandBankIslam:
                XCTAssertEqualObjects(brandID, @"bank_islam");
                XCTAssertEqualObjects(brandName, @"Bank Islam");
                break;
            case STPFPXBankBrandBankMuamalat:
                XCTAssertEqualObjects(brandID, @"bank_muamalat");
                XCTAssertEqualObjects(brandName, @"Bank Muamalat");
                break;
            case STPFPXBankBrandBankRakyat:
                XCTAssertEqualObjects(brandID, @"bank_rakyat");
                XCTAssertEqualObjects(brandName, @"Bank Rakyat");
                break;
            case STPFPXBankBrandBSN:
                XCTAssertEqualObjects(brandID, @"bsn");
                XCTAssertEqualObjects(brandName, @"BSN");
                break;
            case STPFPXBankBrandCIMB:
                XCTAssertEqualObjects(brandID, @"cimb");
                XCTAssertEqualObjects(brandName, @"CIMB Clicks");
                break;
            case STPFPXBankBrandHongLeongBank:
                XCTAssertEqualObjects(brandID, @"hong_leong_bank");
                XCTAssertEqualObjects(brandName, @"Hong Leong Bank");
                break;
            case STPFPXBankBrandHSBC:
                XCTAssertEqualObjects(brandID, @"hsbc");
                XCTAssertEqualObjects(brandName, @"HSBC BANK");
                break;
            case STPFPXBankBrandKFH:
                XCTAssertEqualObjects(brandID, @"kfh");
                XCTAssertEqualObjects(brandName, @"KFH");
                break;
            case STPFPXBankBrandMaybank2E:
                XCTAssertEqualObjects(brandID, @"maybank2e");
                XCTAssertEqualObjects(brandName, @"Maybank2E");
                break;
            case STPFPXBankBrandMaybank2U:
                XCTAssertEqualObjects(brandID, @"maybank2u");
                XCTAssertEqualObjects(brandName, @"Maybank2U");
                break;
            case STPFPXBankBrandOcbc:
                XCTAssertEqualObjects(brandID, @"ocbc");
                XCTAssertEqualObjects(brandName, @"OCBC Bank");
                break;
            case STPFPXBankBrandPublicBank:
                XCTAssertEqualObjects(brandID, @"public_bank");
                XCTAssertEqualObjects(brandName, @"Public Bank");
                break;
            case STPFPXBankBrandRHB:
                XCTAssertEqualObjects(brandID, @"rhb");
                XCTAssertEqualObjects(brandName, @"RHB Bank");
                break;
            case STPFPXBankBrandStandardChartered:
                XCTAssertEqualObjects(brandID, @"standard_chartered");
                XCTAssertEqualObjects(brandName, @"Standard Chartered");
                break;
            case STPFPXBankBrandUOB:
                XCTAssertEqualObjects(brandID, @"uob");
                XCTAssertEqualObjects(brandName, @"UOB Bank");
                break;
            case STPFPXBankBrandUnknown:
                XCTAssertEqualObjects(brandID, @"unknown");
                XCTAssertEqualObjects(brandName, @"Unknown");
                break;
        }
    };
}

@end
