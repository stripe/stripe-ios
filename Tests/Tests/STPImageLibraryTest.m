//
//  STPImageLibraryTest.m
//  Stripe
//
//  Created by Jack Flintermann on 6/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "STPCardBrand.h"
#import "STPImageLibrary.h"
#import "STPImageLibrary+Private.h"

#import "STPTestUtils.h"

@interface STPImageLibraryTest : XCTestCase
@property id mockLocale;
@property NSArray<NSNumber *> *cardBrands;
@end

@implementation STPImageLibraryTest

- (void)setUp {
    [super setUp];

    self.mockLocale = OCMClassMock([NSLocale class]);
    OCMStub([self.mockLocale currentLocale]).andReturn(self.mockLocale);
    OCMStub([self.mockLocale localeIdentifier]).andReturn(@"EN_US");

    self.cardBrands = @[
                        @(STPCardBrandAmex),
                        @(STPCardBrandDinersClub),
                        @(STPCardBrandDiscover),
                        @(STPCardBrandJCB),
                        @(STPCardBrandMasterCard),
                        @(STPCardBrandUnionPay),
                        @(STPCardBrandUnknown),
                        @(STPCardBrandVisa),
                        ];
}

- (void)tearDown {
    [super tearDown];

    [self.mockLocale stopMocking];
}

- (void)testCardIconMethods {
    AssertEqualImages([STPImageLibrary applePayCardImage], [STPImageLibrary safeImageNamed:@"stp_card_applepay" templateIfAvailable:NO]);
    AssertEqualImages([STPImageLibrary amexCardImage], [STPImageLibrary safeImageNamed:@"stp_card_amex" templateIfAvailable:NO]);
    AssertEqualImages([STPImageLibrary dinersClubCardImage], [STPImageLibrary safeImageNamed:@"stp_card_diners" templateIfAvailable:NO]);
    AssertEqualImages([STPImageLibrary discoverCardImage], [STPImageLibrary safeImageNamed:@"stp_card_discover" templateIfAvailable:NO]);
    AssertEqualImages([STPImageLibrary jcbCardImage], [STPImageLibrary safeImageNamed:@"stp_card_jcb" templateIfAvailable:NO]);
    AssertEqualImages([STPImageLibrary masterCardCardImage], [STPImageLibrary safeImageNamed:@"stp_card_mastercard" templateIfAvailable:NO]);
    AssertEqualImages([STPImageLibrary unionPayCardImage], [STPImageLibrary safeImageNamed:@"stp_card_unionpay_en" templateIfAvailable:NO]);
    AssertEqualImages([STPImageLibrary visaCardImage], [STPImageLibrary safeImageNamed:@"stp_card_visa" templateIfAvailable:NO]);
    AssertEqualImages([STPImageLibrary unknownCardCardImage], [STPImageLibrary safeImageNamed:@"stp_card_unknown" templateIfAvailable:YES]);
}

- (void)testBrandImageForCardBrand {
    for (NSNumber *brandNumber in self.cardBrands) {
        STPCardBrand brand = (STPCardBrand)[brandNumber integerValue];
        UIImage *image = [STPImageLibrary brandImageForCardBrand:brand];

        switch (brand) {
            case STPCardBrandVisa:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_visa" templateIfAvailable:NO]);
                break;
            case STPCardBrandAmex:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_amex" templateIfAvailable:NO]);
                break;
            case STPCardBrandMasterCard:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_mastercard" templateIfAvailable:NO]);
                break;
            case STPCardBrandDiscover:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_discover" templateIfAvailable:NO]);
                break;
            case STPCardBrandJCB:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_jcb" templateIfAvailable:NO]);
                break;
            case STPCardBrandDinersClub:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_diners" templateIfAvailable:NO]);
                break;
            case STPCardBrandUnionPay:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_unionpay_en" templateIfAvailable:NO]);
                break;
            case STPCardBrandUnknown:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_unknown" templateIfAvailable:YES]);
                break;
        }
    }
}

- (void)testBrandImageForCardBrand_zh {
    [self.mockLocale stopMocking];

    self.mockLocale = OCMClassMock([NSLocale class]);
    OCMStub([self.mockLocale currentLocale]).andReturn(self.mockLocale);
    OCMStub([self.mockLocale localeIdentifier]).andReturn(@"ZH_HANT");

    UIImage *image = [STPImageLibrary brandImageForCardBrand:STPCardBrandUnionPay];
    AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_unionpay_zh" templateIfAvailable:NO]);
}

- (void)testTemplatedBrandImageForCardBrand {
    for (NSNumber *brandNumber in self.cardBrands) {
        STPCardBrand brand = (STPCardBrand)[brandNumber integerValue];
        UIImage *image = [STPImageLibrary templatedBrandImageForCardBrand:brand];

        switch (brand) {
            case STPCardBrandVisa:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_visa_template" templateIfAvailable:YES]);
                break;
            case STPCardBrandAmex:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_amex_template" templateIfAvailable:YES]);
                break;
            case STPCardBrandMasterCard:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_mastercard_template" templateIfAvailable:YES]);
                break;
            case STPCardBrandDiscover:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_discover_template" templateIfAvailable:YES]);
                break;
            case STPCardBrandJCB:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_jcb_template" templateIfAvailable:YES]);
                break;
            case STPCardBrandDinersClub:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_diners_template" templateIfAvailable:YES]);
                break;
            case STPCardBrandUnionPay:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_unionpay_template_en" templateIfAvailable:YES]);
                break;
            case STPCardBrandUnknown:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_unknown" templateIfAvailable:YES]);
                break;
        }
    }
}

- (void)testTemplatedBrandImageForCardBrand_zh {
    [self.mockLocale stopMocking];

    self.mockLocale = OCMClassMock([NSLocale class]);
    OCMStub([self.mockLocale currentLocale]).andReturn(self.mockLocale);
    OCMStub([self.mockLocale localeIdentifier]).andReturn(@"ZH_HANT");

    UIImage *image = [STPImageLibrary templatedBrandImageForCardBrand:STPCardBrandUnionPay];
    AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_unionpay_template_zh" templateIfAvailable:YES]);
}

- (void)testCVCImageForCardBrand {
    for (NSNumber *brandNumber in self.cardBrands) {
        STPCardBrand brand = (STPCardBrand)[brandNumber integerValue];
        UIImage *image = [STPImageLibrary cvcImageForCardBrand:brand];

        switch (brand) {
            case STPCardBrandAmex:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_cvc_amex" templateIfAvailable:NO]);
                break;

            default:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_cvc" templateIfAvailable:NO]);
                break;
        }
    }
}

- (void)testErrorImageForCardBrand {
    for (NSNumber *brandNumber in self.cardBrands) {
        STPCardBrand brand = (STPCardBrand)[brandNumber integerValue];
        UIImage *image = [STPImageLibrary errorImageForCardBrand:brand];

        switch (brand) {
            case STPCardBrandAmex:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_error_amex" templateIfAvailable:NO]);
                break;

            default:
                AssertEqualImages(image, [STPImageLibrary safeImageNamed:@"stp_card_error" templateIfAvailable:NO]);
                break;
        }
    }
}

@end
