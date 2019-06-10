//
//  STPCardTest.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/5/12.
//
//

@import XCTest;

#import "STPCard.h"
#import "STPCard+Private.h"

#import "NSDictionary+Stripe.h"
#import "STPFixtures.h"
#import "STPTestUtils.h"

@interface STPCard ()

@property (nonatomic, assign, readwrite) STPCardBrand brand;

- (void)setLast4:(NSString *)last4;
- (void)setAllResponseFields:(NSDictionary *)allResponseFields;

@end

@interface STPCardTest : XCTestCase

@end

@implementation STPCardTest

#pragma mark - STPCardBrand Tests

// These are only intended to be deprecated publicly.
// When removed from public header, can remove these pragmas
- (void)testBrandFromString {
    XCTAssertEqual([STPCard brandFromString:@"visa"], STPCardBrandVisa);
    XCTAssertEqual([STPCard brandFromString:@"VISA"], STPCardBrandVisa);

    XCTAssertEqual([STPCard brandFromString:@"american express"], STPCardBrandAmex);
    XCTAssertEqual([STPCard brandFromString:@"AMERICAN EXPRESS"], STPCardBrandAmex);

    XCTAssertEqual([STPCard brandFromString:@"mastercard"], STPCardBrandMasterCard);
    XCTAssertEqual([STPCard brandFromString:@"MASTERCARD"], STPCardBrandMasterCard);

    XCTAssertEqual([STPCard brandFromString:@"discover"], STPCardBrandDiscover);
    XCTAssertEqual([STPCard brandFromString:@"DISCOVER"], STPCardBrandDiscover);

    XCTAssertEqual([STPCard brandFromString:@"jcb"], STPCardBrandJCB);
    XCTAssertEqual([STPCard brandFromString:@"JCB"], STPCardBrandJCB);

    XCTAssertEqual([STPCard brandFromString:@"diners club"], STPCardBrandDinersClub);
    XCTAssertEqual([STPCard brandFromString:@"DINERS CLUB"], STPCardBrandDinersClub);

    XCTAssertEqual([STPCard brandFromString:@"unionpay"], STPCardBrandUnionPay);
    XCTAssertEqual([STPCard brandFromString:@"UNIONPAY"], STPCardBrandUnionPay);

    XCTAssertEqual([STPCard brandFromString:@"unknown"], STPCardBrandUnknown);
    XCTAssertEqual([STPCard brandFromString:@"UNKNOWN"], STPCardBrandUnknown);
    
    XCTAssertEqual([STPCard brandFromString:@"garbage"], STPCardBrandUnknown);
    XCTAssertEqual([STPCard brandFromString:@"GARBAGE"], STPCardBrandUnknown);
}

#pragma mark - STPCardFundingType Tests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
// These are only intended to be deprecated publicly.
// When removed from public header, can remove these pragmas

- (void)testFundingFromString {
    XCTAssertEqual([STPCard fundingFromString:@"credit"], STPCardFundingTypeCredit);
    XCTAssertEqual([STPCard fundingFromString:@"CREDIT"], STPCardFundingTypeCredit);

    XCTAssertEqual([STPCard fundingFromString:@"debit"], STPCardFundingTypeDebit);
    XCTAssertEqual([STPCard fundingFromString:@"DEBIT"], STPCardFundingTypeDebit);

    XCTAssertEqual([STPCard fundingFromString:@"prepaid"], STPCardFundingTypePrepaid);
    XCTAssertEqual([STPCard fundingFromString:@"PREPAID"], STPCardFundingTypePrepaid);

    XCTAssertEqual([STPCard fundingFromString:@"other"], STPCardFundingTypeOther);
    XCTAssertEqual([STPCard fundingFromString:@"OTHER"], STPCardFundingTypeOther);

    XCTAssertEqual([STPCard fundingFromString:@"unknown"], STPCardFundingTypeOther);
    XCTAssertEqual([STPCard fundingFromString:@"UNKNOWN"], STPCardFundingTypeOther);

    XCTAssertEqual([STPCard fundingFromString:@"garbage"], STPCardFundingTypeOther);
    XCTAssertEqual([STPCard fundingFromString:@"GARBAGE"], STPCardFundingTypeOther);
}

#pragma clang diagnostic pop

- (void)testStringFromFunding {
    NSArray<NSNumber *> *values = @[
                                    @(STPCardFundingTypeCredit),
                                    @(STPCardFundingTypeDebit),
                                    @(STPCardFundingTypePrepaid),
                                    @(STPCardFundingTypeOther),
                                    ];

    for (NSNumber *fundingNumber in values) {
        STPCardFundingType funding = (STPCardFundingType)[fundingNumber integerValue];
        NSString *string = [STPCard stringFromFunding:funding];

        switch (funding) {
            case STPCardFundingTypeCredit:
                XCTAssertEqualObjects(string, @"credit");
                break;
            case STPCardFundingTypeDebit:
                XCTAssertEqualObjects(string, @"debit");
                break;
            case STPCardFundingTypePrepaid:
                XCTAssertEqualObjects(string, @"prepaid");
                break;
            case STPCardFundingTypeOther:
                XCTAssertNil(string);
                break;
        }
    }
}

#pragma mark -
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
// These tests can ber removed in the future, they should be covered by
// the equivalent response decodeable tests

- (void)testInitWithIDBrandLast4ExpMonthExpYearFunding {
    STPCard *card = [[STPCard alloc] initWithID:@"card_1AVRojEOD54MuFwSxr93QJSx"
                                          brand:STPCardBrandVisa
                                          last4:@"5556"
                                       expMonth:12
                                        expYear:2034
                                        funding:STPCardFundingTypeDebit];
    XCTAssertEqualObjects(card.stripeID, @"card_1AVRojEOD54MuFwSxr93QJSx");
    XCTAssertEqual(card.brand, STPCardBrandVisa);
    XCTAssertEqualObjects(card.last4, @"5556");
    XCTAssertEqual(card.expMonth, (NSUInteger)12);
    XCTAssertEqual(card.expYear, (NSUInteger)2034);
    XCTAssertEqual(card.funding, STPCardFundingTypeDebit);
}

#pragma clang diagnostic pop

- (void)testIsApplePayCard {
    STPCard *card = [STPFixtures card];

    card.allResponseFields = @{};
    XCTAssertFalse(card.isApplePayCard);

    card.allResponseFields = @{@"tokenization_method": @"android_pay"};
    XCTAssertFalse(card.isApplePayCard);

    card.allResponseFields = @{@"tokenization_method": @"apple_pay"};
    XCTAssert(card.isApplePayCard);

    card.allResponseFields = @{@"tokenization_method": @"garbage"};
    XCTAssertFalse(card.isApplePayCard);

    card.allResponseFields = @{@"tokenization_method": @""};
    XCTAssertFalse(card.isApplePayCard);

    // See: https://stripe.com/docs/api#card_object-tokenization_method
}

- (void)testAddressPopulated {
    STPCard *card = [STPFixtures card];
    XCTAssertEqualObjects(card.address.name, @"Jane Austen");
    XCTAssertEqualObjects(card.address.line1, @"123 Fake St");
    XCTAssertEqualObjects(card.address.line2, @"Apt 1");
    XCTAssertEqualObjects(card.address.city, @"Pittsburgh");
    XCTAssertEqualObjects(card.address.state, @"PA");
    XCTAssertEqualObjects(card.address.postalCode, @"19219");
    XCTAssertEqualObjects(card.address.country, @"US");
}

#pragma mark - Equality Tests

- (void)testCardEquals {
    STPCard *card1 = [STPFixtures card];
    STPCard *card2 = [STPFixtures card];

    XCTAssertNotEqual(card1, card2);

    XCTAssertEqualObjects(card1, card1);
    XCTAssertEqualObjects(card1, card2);

    XCTAssertEqual(card1.hash, card1.hash);
    XCTAssertEqual(card1.hash, card2.hash);
}

#pragma mark - Description Tests

- (void)testDescription {
    STPCard *card = [STPFixtures card];
    XCTAssert(card.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[
                                            @"id",
                                            @"last4",
                                            @"brand",
                                            @"exp_month",
                                            @"exp_year",
                                            ];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:@"Card"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPCard decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"Card"]]);
}



- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:@"Card"];
    STPCard *card = [STPCard decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(card.stripeID, @"card_103kbR2eZvKYlo2CDczLmw4K");

    XCTAssertEqualObjects(card.address.city, @"Pittsburgh");
    XCTAssertEqualObjects(card.address.country, @"US");
    XCTAssertEqualObjects(card.address.line1, @"123 Fake St");
    XCTAssertEqualObjects(card.address.line2, @"Apt 1");
    XCTAssertEqualObjects(card.address.state, @"PA");
    XCTAssertEqualObjects(card.address.postalCode, @"19219");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

    XCTAssertEqualObjects(card.cardId, @"card_103kbR2eZvKYlo2CDczLmw4K");

    XCTAssertEqualObjects(card.addressCity, @"Pittsburgh");
    XCTAssertEqualObjects(card.addressCountry, @"US");
    XCTAssertEqualObjects(card.addressLine1, @"123 Fake St");
    XCTAssertEqualObjects(card.addressLine2, @"Apt 1");
    XCTAssertEqualObjects(card.addressState, @"PA");
    XCTAssertEqualObjects(card.addressZip, @"19219");

#pragma clang diagnostic pop

    XCTAssertEqual(card.brand, STPCardBrandVisa);
    XCTAssertEqualObjects(card.country, @"US");
    XCTAssertEqualObjects(card.currency, @"usd");
    XCTAssertEqualObjects(card.dynamicLast4, @"5678");
    XCTAssertEqual(card.expMonth, (NSUInteger)5);
    XCTAssertEqual(card.expYear, (NSUInteger)2017);
    XCTAssertEqual(card.funding, STPCardFundingTypeCredit);
    XCTAssertEqualObjects(card.last4, @"4242");
    XCTAssertEqualObjects(card.metadata, @{@"order_id": @"6735"});
    XCTAssertEqualObjects(card.name, @"Jane Austen");

    XCTAssertNotEqual(card.allResponseFields, response);
    XCTAssertEqualObjects(card.allResponseFields, [response stp_dictionaryByRemovingNulls]);
}



#pragma mark - STPSourceProtocol Tests

- (void)testStripeID {
    STPCard *card = [STPFixtures card];
    XCTAssertEqualObjects(card.stripeID, @"card_103kbR2eZvKYlo2CDczLmw4K");
}

#pragma mark - STPPaymentOption Tests

- (void)testImage {
    STPCard *card = [STPFixtures card];
    [self forEachBrand:^(STPCardBrand brand) {
        card.brand = brand;
        XCTAssert([card image]);
    }];
}

- (void)testTemplateImage {
    STPCard *card = [STPFixtures card];
    [self forEachBrand:^(STPCardBrand brand) {
        card.brand = brand;

        XCTAssert([card templateImage]);
    }];
}

- (void)testLabel {
    STPCard *card = [STPCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"Card"]];
    XCTAssertEqualObjects(card.label, @"Visa 4242");
}

#pragma mark -

- (void)forEachBrand:(void (^)(STPCardBrand brand))block {
    NSArray<NSNumber *> *values = @[
                                    @(STPCardBrandAmex),
                                    @(STPCardBrandDinersClub),
                                    @(STPCardBrandDiscover),
                                    @(STPCardBrandJCB),
                                    @(STPCardBrandMasterCard),
                                    @(STPCardBrandUnionPay),
                                    @(STPCardBrandVisa),
                                    @(STPCardBrandUnknown),
                                    ];

    for (NSNumber *brandNumber in values) {
        block((STPCardBrand)[brandNumber integerValue]);
    }
}

@end
