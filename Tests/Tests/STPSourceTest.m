//
//  STPSourceTest.m
//  Stripe
//
//  Created by Ben Guo on 1/24/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPSource.h"
#import "STPSource+Private.h"

#import "STPTestUtils.h"

@interface STPSource ()

+ (STPSourceFlow)flowFromString:(NSString *)string;

+ (STPSourceStatus)statusFromString:(NSString *)string;
+ (NSString *)stringFromStatus:(STPSourceStatus)status;

+ (STPSourceUsage)usageFromString:(NSString *)string;

@end

@interface STPSourceTest : XCTestCase

@end

@implementation STPSourceTest

#pragma mark - STPSourceType Tests

- (void)testTypeFromString {
    XCTAssertEqual([STPSource typeFromString:@"bancontact"], STPSourceTypeBancontact);
    XCTAssertEqual([STPSource typeFromString:@"BANCONTACT"], STPSourceTypeBancontact);

    XCTAssertEqual([STPSource typeFromString:@"bitcoin"], STPSourceTypeBitcoin);
    XCTAssertEqual([STPSource typeFromString:@"BITCOIN"], STPSourceTypeBitcoin);

    XCTAssertEqual([STPSource typeFromString:@"card"], STPSourceTypeCard);
    XCTAssertEqual([STPSource typeFromString:@"CARD"], STPSourceTypeCard);

    XCTAssertEqual([STPSource typeFromString:@"giropay"], STPSourceTypeGiropay);
    XCTAssertEqual([STPSource typeFromString:@"GIROPAY"], STPSourceTypeGiropay);

    XCTAssertEqual([STPSource typeFromString:@"ideal"], STPSourceTypeIDEAL);
    XCTAssertEqual([STPSource typeFromString:@"IDEAL"], STPSourceTypeIDEAL);

    XCTAssertEqual([STPSource typeFromString:@"sepa_debit"], STPSourceTypeSEPADebit);
    XCTAssertEqual([STPSource typeFromString:@"SEPA_DEBIT"], STPSourceTypeSEPADebit);

    XCTAssertEqual([STPSource typeFromString:@"sofort"], STPSourceTypeSofort);
    XCTAssertEqual([STPSource typeFromString:@"SOFORT"], STPSourceTypeSofort);

    XCTAssertEqual([STPSource typeFromString:@"three_d_secure"], STPSourceTypeThreeDSecure);
    XCTAssertEqual([STPSource typeFromString:@"THREE_D_SECURE"], STPSourceTypeThreeDSecure);

    XCTAssertEqual([STPSource typeFromString:@"alipay"], STPSourceTypeAlipay);
    XCTAssertEqual([STPSource typeFromString:@"ALIPAY"], STPSourceTypeAlipay);

    XCTAssertEqual([STPSource typeFromString:@"p24"], STPSourceTypeP24);
    XCTAssertEqual([STPSource typeFromString:@"P24"], STPSourceTypeP24);

    XCTAssertEqual([STPSource typeFromString:@"unknown"], STPSourceTypeUnknown);
    XCTAssertEqual([STPSource typeFromString:@"UNKNOWN"], STPSourceTypeUnknown);

    XCTAssertEqual([STPSource typeFromString:@"garbage"], STPSourceTypeUnknown);
    XCTAssertEqual([STPSource typeFromString:@"GARBAGE"], STPSourceTypeUnknown);
}

- (void)testStringFromType {
    NSArray<NSNumber *> *values = @[
                                    @(STPSourceTypeBancontact),
                                    @(STPSourceTypeBitcoin),
                                    @(STPSourceTypeCard),
                                    @(STPSourceTypeGiropay),
                                    @(STPSourceTypeIDEAL),
                                    @(STPSourceTypeSEPADebit),
                                    @(STPSourceTypeSofort),
                                    @(STPSourceTypeThreeDSecure),
                                    @(STPSourceTypeAlipay),
                                    @(STPSourceTypeP24),
                                    @(STPSourceTypeUnknown),
                                    ];

    for (NSNumber *typeNumber in values) {
        STPSourceType type = (STPSourceType)[typeNumber integerValue];
        NSString *string = [STPSource stringFromType:type];

        switch (type) {
            case STPSourceTypeBancontact:
                XCTAssertEqualObjects(string, @"bancontact");
                break;
            case STPSourceTypeBitcoin:
                XCTAssertEqualObjects(string, @"bitcoin");
                break;
            case STPSourceTypeCard:
                XCTAssertEqualObjects(string, @"card");
                break;
            case STPSourceTypeGiropay:
                XCTAssertEqualObjects(string, @"giropay");
                break;
            case STPSourceTypeIDEAL:
                XCTAssertEqualObjects(string, @"ideal");
                break;
            case STPSourceTypeSEPADebit:
                XCTAssertEqualObjects(string, @"sepa_debit");
                break;
            case STPSourceTypeSofort:
                XCTAssertEqualObjects(string, @"sofort");
                break;
            case STPSourceTypeThreeDSecure:
                XCTAssertEqualObjects(string, @"three_d_secure");
                break;
            case STPSourceTypeAlipay:
                XCTAssertEqualObjects(string, @"alipay");
                break;
            case STPSourceTypeP24:
                XCTAssertEqualObjects(string, @"p24");
                break;
            case STPSourceTypeUnknown:
                XCTAssertNil(string);
                break;
        }
    }
}

#pragma mark - STPSourceFlow Tests

- (void)testFlowFromString {
    XCTAssertEqual([STPSource flowFromString:@"redirect"], STPSourceFlowRedirect);
    XCTAssertEqual([STPSource flowFromString:@"REDIRECT"], STPSourceFlowRedirect);

    XCTAssertEqual([STPSource flowFromString:@"receiver"], STPSourceFlowReceiver);
    XCTAssertEqual([STPSource flowFromString:@"RECEIVER"], STPSourceFlowReceiver);

    XCTAssertEqual([STPSource flowFromString:@"code_verification"], STPSourceFlowCodeVerification);
    XCTAssertEqual([STPSource flowFromString:@"CODE_VERIFICATION"], STPSourceFlowCodeVerification);

    XCTAssertEqual([STPSource flowFromString:@"none"], STPSourceFlowNone);
    XCTAssertEqual([STPSource flowFromString:@"NONE"], STPSourceFlowNone);

    XCTAssertEqual([STPSource flowFromString:@"garbage"], STPSourceFlowUnknown);
    XCTAssertEqual([STPSource flowFromString:@"GARBAGE"], STPSourceFlowUnknown);
}

- (void)testStringFromFlow {
    NSArray<NSNumber *> *values = @[
                                    @(STPSourceFlowRedirect),
                                    @(STPSourceFlowReceiver),
                                    @(STPSourceFlowCodeVerification),
                                    @(STPSourceFlowNone),
                                    @(STPSourceFlowUnknown),
                                    ];

    for (NSNumber *flowNumber in values) {
        STPSourceFlow flow = (STPSourceFlow)[flowNumber integerValue];
        NSString *string = [STPSource stringFromFlow:flow];

        switch (flow) {
            case STPSourceFlowRedirect:
                XCTAssertEqualObjects(string, @"redirect");
                break;
            case STPSourceFlowReceiver:
                XCTAssertEqualObjects(string, @"receiver");
                break;
            case STPSourceFlowCodeVerification:
                XCTAssertEqualObjects(string, @"code_verification");
                break;
            case STPSourceFlowNone:
                XCTAssertEqualObjects(string, @"none");
                break;
            case STPSourceFlowUnknown:
                XCTAssertNil(string);
                break;
        }
    }
}

#pragma mark - STPSourceStatus Tests

- (void)testStatusFromString {
    XCTAssertEqual([STPSource statusFromString:@"pending"], STPSourceStatusPending);
    XCTAssertEqual([STPSource statusFromString:@"PENDING"], STPSourceStatusPending);

    XCTAssertEqual([STPSource statusFromString:@"chargeable"], STPSourceStatusChargeable);
    XCTAssertEqual([STPSource statusFromString:@"CHARGEABLE"], STPSourceStatusChargeable);

    XCTAssertEqual([STPSource statusFromString:@"consumed"], STPSourceStatusConsumed);
    XCTAssertEqual([STPSource statusFromString:@"CONSUMED"], STPSourceStatusConsumed);

    XCTAssertEqual([STPSource statusFromString:@"canceled"], STPSourceStatusCanceled);
    XCTAssertEqual([STPSource statusFromString:@"CANCELED"], STPSourceStatusCanceled);

    XCTAssertEqual([STPSource statusFromString:@"failed"], STPSourceStatusFailed);
    XCTAssertEqual([STPSource statusFromString:@"FAILED"], STPSourceStatusFailed);

    XCTAssertEqual([STPSource statusFromString:@"garbage"], STPSourceStatusUnknown);
    XCTAssertEqual([STPSource statusFromString:@"GARBAGE"], STPSourceStatusUnknown);
}

- (void)testStringFromStatus {
    NSArray<NSNumber *> *values = @[
                                    @(STPSourceStatusPending),
                                    @(STPSourceStatusChargeable),
                                    @(STPSourceStatusConsumed),
                                    @(STPSourceStatusCanceled),
                                    @(STPSourceStatusFailed),
                                    @(STPSourceStatusUnknown),
                                    ];

    for (NSNumber *statusNumber in values) {
        STPSourceStatus status = (STPSourceStatus)[statusNumber integerValue];
        NSString *string = [STPSource stringFromStatus:status];

        switch (status) {
            case STPSourceStatusPending:
                XCTAssertEqualObjects(string, @"pending");
                break;
            case STPSourceStatusChargeable:
                XCTAssertEqualObjects(string, @"chargeable");
                break;
            case STPSourceStatusConsumed:
                XCTAssertEqualObjects(string, @"consumed");
                break;
            case STPSourceStatusCanceled:
                XCTAssertEqualObjects(string, @"canceled");
                break;
            case STPSourceStatusFailed:
                XCTAssertEqualObjects(string, @"failed");
                break;
            case STPSourceStatusUnknown:
                XCTAssertNil(string);
                break;
        }
    }
}

#pragma mark - STPSourceUsage Tests

- (void)testUsageFromString {
    XCTAssertEqual([STPSource usageFromString:@"reusable"], STPSourceUsageReusable);
    XCTAssertEqual([STPSource usageFromString:@"REUSABLE"], STPSourceUsageReusable);

    XCTAssertEqual([STPSource usageFromString:@"single_use"], STPSourceUsageSingleUse);
    XCTAssertEqual([STPSource usageFromString:@"SINGLE_USE"], STPSourceUsageSingleUse);

    XCTAssertEqual([STPSource usageFromString:@"garbage"], STPSourceUsageUnknown);
    XCTAssertEqual([STPSource usageFromString:@"GARBAGE"], STPSourceUsageUnknown);
}

- (void)testStringFromUsage {
    NSArray<NSNumber *> *values = @[
                                    @(STPSourceUsageReusable),
                                    @(STPSourceUsageSingleUse),
                                    @(STPSourceUsageUnknown),
                                    ];

    for (NSNumber *usageNumber in values) {
        STPSourceUsage usage = (STPSourceUsage)[usageNumber integerValue];
        NSString *string = [STPSource stringFromUsage:usage];

        switch (usage) {
            case STPSourceUsageReusable:
                XCTAssertEqualObjects(string, @"reusable");
                break;
            case STPSourceUsageSingleUse:
                XCTAssertEqualObjects(string, @"single_use");
                break;
            case STPSourceUsageUnknown:
                XCTAssertNil(string);
                break;
        }
    }
}

#pragma mark - Equality Tests

- (void)testSourceEquals {
    STPSource *source1 = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"BitcoinSource"]];
    STPSource *source2 = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"BitcoinSource"]];

    XCTAssertNotEqual(source1, source2);

    XCTAssertEqualObjects(source1, source1);
    XCTAssertEqualObjects(source1, source2);

    XCTAssertEqual(source1.hash, source1.hash);
    XCTAssertEqual(source1.hash, source2.hash);
}

#pragma mark - Description Tests

- (void)testDescription {
    STPSource *source = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"BitcoinSource"]];
    XCTAssert(source.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[
                                            @"id",
                                            @"livemode",
                                            @"status",
                                            @"type",
                                            ];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:@"BitcoinSource"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSource decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"BitcoinSource"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:@"BitcoinSource"];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(source.stripeID, @"src_1AZnr12eZvKYlo2Cl6OACPB1");
    XCTAssertEqualObjects(source.amount, @(1000));
    XCTAssertEqualObjects(source.clientSecret, @"src_client_secret_rAzjPq1N4nWJ1iVqxAzGZzix");
    XCTAssertEqualObjects(source.created, [NSDate dateWithTimeIntervalSince1970:1498685863]);
    XCTAssertEqualObjects(source.currency, @"usd");
    XCTAssertEqual(source.flow, STPSourceFlowReceiver);
    XCTAssertFalse(source.livemode);
    XCTAssertEqualObjects(source.metadata, @{@"order_id": @"6735"});
    XCTAssert(source.owner);  // STPSourceOwnerTest
    XCTAssert(source.receiver);  // STPSourceReceiverTest
    XCTAssertEqual(source.status, STPSourceStatusPending);
    XCTAssertEqual(source.type, STPSourceTypeBitcoin);
    XCTAssertEqual(source.usage, STPSourceUsageSingleUse);
    XCTAssertEqualObjects(source.details, response[@"bitcoin"]);

    XCTAssertNotEqual(source.allResponseFields, response);
    XCTAssertEqualObjects(source.allResponseFields, response);
}

- (NSDictionary *)buildTestResponse_ideal {
    // Source: https://stripe.com/docs/sources/ideal
    NSDictionary *dict = @{
                           @"id": @"src_123",
                           @"object": @"source",
                           @"amount": @1099,
                           @"client_secret": @"src_client_secret_123",
                           @"created": @1445277809,
                           @"currency": @"eur",
                           @"flow": @"redirect",
                           @"livemode": @YES,
                           @"owner": @{
                                   @"address": [NSNull null],
                                   @"email": [NSNull null],
                                   @"name": @"Jenny Rosen",
                                   @"phone": [NSNull null],
                                   @"verified_address": [NSNull null],
                                   @"verified_email": [NSNull null],
                                   @"verified_name": @"Jenny Rosen",
                                   @"verified_phone": [NSNull null],
                                   },
                           @"redirect": @{
                                   @"return_url": @"https://shop.foo.com/crtABC",
                                   @"status": @"pending",
                                   @"url": @"https://pay.stripe.com/redirect/src_123?client_secret=src_client_secret_123"
                                   },
                           @"status": @"pending",
                           @"type": @"ideal",
                           @"usage": @"single_use",
                           @"ideal": @{
                                   @"bank": @"ing"
                                   }
                           };
    return dict;
}

- (NSDictionary *)buildTestResponse_sepa_debit {
    // Source: https://stripe.com/docs/sources/sepa-debit
    NSDictionary *dict = @{
                           @"id": @"src_123",
                           @"object": @"source",
                           @"amount": [NSNull null],
                           @"client_secret": @"src_client_secret_123",
                           @"created": @1445277809,
                           @"currency": @"eur",
                           @"flow": @"none",
                           @"livemode": @NO,
                           @"owner": @{
                                   @"address": @{
                                           @"city": @"Berlin",
                                           @"country": @"DE",
                                           @"line1": @"Nollendorfstraße 27",
                                           @"line2": [NSNull null],
                                           @"postal_code": @"10777",
                                           @"state": [NSNull null]
                                           },
                                   @"email": [NSNull null],
                                   @"name": @"Jenny Rosen",
                                   @"phone": [NSNull null],
                                   @"verified_address": [NSNull null],
                                   @"verified_email": [NSNull null],
                                   @"verified_name": [NSNull null],
                                   @"verified_phone": [NSNull null],
                                   },
                           @"status": @"chargeable",
                           @"type": @"sepa_debit",
                           @"usage": @"reusable",
                           @"sepa_debit": @{
                                   @"bank_code": @37040044,
                                   @"country": @"DE",
                                   @"fingerprint": @"NxdSyRegc9PsMkWy",
                                   @"last4": @3001,
                                   @"mandate_reference": @"NXDSYREGC9PSMKWY",
                                   @"mandate_url": @"https://hooks.stripe.com/adapter/sepa_debit/file/src_123/src_client_secret_123"
                                   }
                           };
    return dict;
}

- (void)testDecodingSource_ideal {
    NSDictionary *response = [self buildTestResponse_ideal];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(source.stripeID, @"src_123");
    XCTAssertEqualObjects(source.amount, @1099);
    XCTAssertEqualObjects(source.clientSecret, @"src_client_secret_123");
    XCTAssertEqualWithAccuracy([source.created timeIntervalSince1970], 1445277809.0, 1.0);
    XCTAssertEqualObjects(source.currency, @"eur");
    XCTAssertEqual(source.flow, STPSourceFlowRedirect);
    XCTAssertEqual(source.livemode, YES);
    XCTAssertEqualObjects(source.owner.name, @"Jenny Rosen");
    XCTAssertEqualObjects(source.owner.verifiedName, @"Jenny Rosen");
    XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
    XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.foo.com/crtABC"]);
    XCTAssertEqualObjects(source.redirect.url, [NSURL URLWithString:@"https://pay.stripe.com/redirect/src_123?client_secret=src_client_secret_123"]);
    XCTAssertEqual(source.status, STPSourceStatusPending);
    XCTAssertEqual(source.type, STPSourceTypeIDEAL);
    XCTAssertEqual(source.usage, STPSourceUsageSingleUse);
    XCTAssertEqualObjects(source.details, response[@"ideal"]);
}

- (void)testDecodingSource_sepa_debit {
    NSDictionary *response = [self buildTestResponse_sepa_debit];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(source.stripeID, @"src_123");
    XCTAssertNil(source.amount);
    XCTAssertEqualObjects(source.clientSecret, @"src_client_secret_123");
    XCTAssertEqualWithAccuracy([source.created timeIntervalSince1970], 1445277809.0, 1.0);
    XCTAssertEqualObjects(source.currency, @"eur");
    XCTAssertEqual(source.flow, STPSourceFlowNone);
    XCTAssertEqual(source.livemode, NO);
    XCTAssertEqualObjects(source.owner.name, @"Jenny Rosen");
    XCTAssertEqualObjects(source.owner.address.city, @"Berlin");
    XCTAssertEqualObjects(source.owner.address.country, @"DE");
    XCTAssertEqualObjects(source.owner.address.line1, @"Nollendorfstraße 27");
    XCTAssertEqualObjects(source.owner.address.postalCode, @"10777");
    XCTAssertEqual(source.status, STPSourceStatusChargeable);
    XCTAssertEqual(source.type, STPSourceTypeSEPADebit);
    XCTAssertEqual(source.usage, STPSourceUsageReusable);
    XCTAssertEqualObjects(source.details, response[@"sepa_debit"]);
}

@end
