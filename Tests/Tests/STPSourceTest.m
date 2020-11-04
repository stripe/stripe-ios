//
//  STPSourceTest.m
//  Stripe
//
//  Created by Ben Guo on 1/24/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;


#import "STPFixtures.h"
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

    XCTAssertEqual([STPSource typeFromString:@"card"], STPSourceTypeCard);
    XCTAssertEqual([STPSource typeFromString:@"CARD"], STPSourceTypeCard);

    XCTAssertEqual([STPSource typeFromString:@"giropay"], STPSourceTypeGiropay);
    XCTAssertEqual([STPSource typeFromString:@"GIROPAY"], STPSourceTypeGiropay);

    XCTAssertEqual([STPSource typeFromString:@"ideal"], STPSourceTypeiDEAL);
    XCTAssertEqual([STPSource typeFromString:@"IDEAL"], STPSourceTypeiDEAL);

    XCTAssertEqual([STPSource typeFromString:@"sepa_debit"], STPSourceTypeSEPADebit);
    XCTAssertEqual([STPSource typeFromString:@"SEPA_DEBIT"], STPSourceTypeSEPADebit);

    XCTAssertEqual([STPSource typeFromString:@"sofort"], STPSourceTypeSofort);
    XCTAssertEqual([STPSource typeFromString:@"Sofort"], STPSourceTypeSofort);

    XCTAssertEqual([STPSource typeFromString:@"three_d_secure"], STPSourceTypeThreeDSecure);
    XCTAssertEqual([STPSource typeFromString:@"THREE_D_SECURE"], STPSourceTypeThreeDSecure);

    XCTAssertEqual([STPSource typeFromString:@"alipay"], STPSourceTypeAlipay);
    XCTAssertEqual([STPSource typeFromString:@"ALIPAY"], STPSourceTypeAlipay);

    XCTAssertEqual([STPSource typeFromString:@"p24"], STPSourceTypeP24);
    XCTAssertEqual([STPSource typeFromString:@"P24"], STPSourceTypeP24);

    XCTAssertEqual([STPSource typeFromString:@"eps"], STPSourceTypeEPS);
    XCTAssertEqual([STPSource typeFromString:@"EPS"], STPSourceTypeEPS);

    XCTAssertEqual([STPSource typeFromString:@"multibanco"], STPSourceTypeMultibanco);
    XCTAssertEqual([STPSource typeFromString:@"MULTIBANCO"], STPSourceTypeMultibanco);

    XCTAssertEqual([STPSource typeFromString:@"unknown"], STPSourceTypeUnknown);
    XCTAssertEqual([STPSource typeFromString:@"UNKNOWN"], STPSourceTypeUnknown);

    XCTAssertEqual([STPSource typeFromString:@"garbage"], STPSourceTypeUnknown);
    XCTAssertEqual([STPSource typeFromString:@"GARBAGE"], STPSourceTypeUnknown);
}

- (void)testStringFromType {
    NSArray<NSNumber *> *values = @[
                                    @(STPSourceTypeBancontact),
                                    @(STPSourceTypeCard),
                                    @(STPSourceTypeGiropay),
                                    @(STPSourceTypeiDEAL),
                                    @(STPSourceTypeSEPADebit),
                                    @(STPSourceTypeSofort),
                                    @(STPSourceTypeThreeDSecure),
                                    @(STPSourceTypeAlipay),
                                    @(STPSourceTypeP24),
                                    @(STPSourceTypeEPS),
                                    @(STPSourceTypeMultibanco),
                                    @(STPSourceTypeUnknown),
                                    ];

    for (NSNumber *typeNumber in values) {
        STPSourceType type = (STPSourceType)[typeNumber integerValue];
        NSString *string = [STPSource stringFromType:type];

        switch (type) {
            case STPSourceTypeBancontact:
                XCTAssertEqualObjects(string, @"bancontact");
                break;
            case STPSourceTypeCard:
                XCTAssertEqualObjects(string, @"card");
                break;
            case STPSourceTypeGiropay:
                XCTAssertEqualObjects(string, @"giropay");
                break;
            case STPSourceTypeiDEAL:
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
            case STPSourceTypeEPS:
                XCTAssertEqualObjects(string, @"eps");
                break;
            case STPSourceTypeMultibanco:
                XCTAssertEqualObjects(string, @"multibanco");
                break;
            case STPSourceTypeWeChatPay:
                XCTAssertEqualObjects(string, @"wechat");
                break;
            case STPSourceTypeKlarna:
                XCTAssertEqualObjects(string, @"klarna");
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
    STPSource *source1 = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"AlipaySource"]];
    STPSource *source2 = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"AlipaySource"]];

    XCTAssertNotEqual(source1, source2);

    XCTAssertEqualObjects(source1, source1);
    XCTAssertEqualObjects(source1, source2);

    XCTAssertEqual(source1.hash, source1.hash);
    XCTAssertEqual(source1.hash, source2.hash);
}

#pragma mark - Description Tests

- (void)testDescription {
    STPSource *source = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"AlipaySource"]];
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
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:@"AlipaySource"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSource decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"AlipaySource"]]);
}

- (void)testDecodingSource_3ds {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONSource3DS];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(source.stripeID, @"src_456");
    XCTAssertEqualObjects(source.amount, @1099);
    XCTAssertEqualObjects(source.clientSecret, @"src_client_secret_456");
    XCTAssertEqualWithAccuracy([source.created timeIntervalSince1970], 1483663790.0, 1.0);
    XCTAssertEqualObjects(source.currency, @"eur");
    XCTAssertEqual(source.flow, STPSourceFlowRedirect);
    XCTAssertEqual(source.livemode, NO);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertNil(source.metadata);
#pragma clang diagnostic pop
    XCTAssert(source.owner);  // STPSourceOwnerTest
    XCTAssert(source.receiver);  // STPSourceReceiverTest
    XCTAssert(source.redirect);  // STPSourceRedirectTest
    XCTAssertEqual(source.status, STPSourceStatusPending);
    XCTAssertEqual(source.type, STPSourceTypeThreeDSecure);
    XCTAssertEqual(source.usage, STPSourceUsageSingleUse);
    XCTAssertNil(source.verification);
    XCTAssertEqualObjects(source.details, [response[@"three_d_secure"] stp_dictionaryByRemovingNulls]);
    XCTAssertNil(source.cardDetails);  // STPSourceCardDetailsTest
    XCTAssertNil(source.sepaDebitDetails);  // STPSourceSEPADebitDetailsTest
    XCTAssertNotEqual(source.allResponseFields, response);  // Verify is copy
    XCTAssertEqualObjects(source.allResponseFields, [response stp_dictionaryByRemovingNulls]);
}

- (void)testDecodingSource_alipay {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONSourceAlipay];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(source.stripeID, @"src_123");
    XCTAssertEqualObjects(source.amount, @1099);
    XCTAssertEqualObjects(source.clientSecret, @"src_client_secret_123");
    XCTAssertEqualWithAccuracy([source.created timeIntervalSince1970], 1445277809.0, 1.0);
    XCTAssertEqualObjects(source.currency, @"usd");
    XCTAssertEqual(source.flow, STPSourceFlowRedirect);
    XCTAssertEqual(source.livemode, YES);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertNil(source.metadata);
#pragma clang diagnostic pop
    XCTAssert(source.owner);  // STPSourceOwnerTest
    XCTAssertNil(source.receiver);  // STPSourceReceiverTest
    XCTAssert(source.redirect);  // STPSourceRedirectTest
    XCTAssertEqual(source.status, STPSourceStatusPending);
    XCTAssertEqual(source.type, STPSourceTypeAlipay);
    XCTAssertEqual(source.usage, STPSourceUsageSingleUse);
    XCTAssertNil(source.verification);
    XCTAssertEqualObjects(source.details, [response[@"alipay"] stp_dictionaryByRemovingNulls]);
    XCTAssertNil(source.cardDetails);  // STPSourceCardDetailsTest
    XCTAssertNil(source.sepaDebitDetails);  // STPSourceSEPADebitDetailsTest
    XCTAssertNotEqual(source.allResponseFields, response);  // Verify is copy
    XCTAssertEqualObjects(source.allResponseFields, [response stp_dictionaryByRemovingNulls]);
}

- (void)testDecodingSource_card {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONSourceCard];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(source.stripeID, @"src_123");
    XCTAssertNil(source.amount);
    XCTAssertEqualObjects(source.clientSecret, @"src_client_secret_123");
    XCTAssertEqualWithAccuracy([source.created timeIntervalSince1970], 1483575790.0, 1.0);
    XCTAssertNil(source.currency);
    XCTAssertEqual(source.flow, STPSourceFlowNone);
    XCTAssertEqual(source.livemode, NO);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertNil(source.metadata);
#pragma clang diagnostic pop
    XCTAssert(source.owner);  // STPSourceOwnerTest
    XCTAssertNil(source.receiver);  // STPSourceReceiverTest
    XCTAssertNil(source.redirect);  // STPSourceRedirectTest
    XCTAssertEqual(source.status, STPSourceStatusChargeable);
    XCTAssertEqual(source.type, STPSourceTypeCard);
    XCTAssertEqual(source.usage, STPSourceUsageReusable);
    XCTAssertNil(source.verification);
    XCTAssertEqualObjects(source.details, response[@"card"]);
    XCTAssert(source.cardDetails);  // STPSourceCardDetailsTest
    XCTAssertNil(source.sepaDebitDetails);  // STPSourceSEPADebitDetailsTest
    XCTAssertNotEqual(source.allResponseFields, response);  // Verify is copy
    XCTAssertEqualObjects(source.allResponseFields, [response stp_dictionaryByRemovingNulls]);
}

- (void)testDecodingSource_ideal {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONSourceiDEAL];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(source.stripeID, @"src_123");
    XCTAssertEqualObjects(source.amount, @1099);
    XCTAssertEqualObjects(source.clientSecret, @"src_client_secret_123");
    XCTAssertEqualWithAccuracy([source.created timeIntervalSince1970], 1445277809.0, 1.0);
    XCTAssertEqualObjects(source.currency, @"eur");
    XCTAssertEqual(source.flow, STPSourceFlowRedirect);
    XCTAssertEqual(source.livemode, YES);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertNil(source.metadata);
#pragma clang diagnostic pop
    XCTAssert(source.owner);  // STPSourceOwnerTest
    XCTAssertNil(source.receiver);  // STPSourceReceiverTest
    XCTAssert(source.redirect);  // STPSourceRedirectTest
    XCTAssertEqual(source.status, STPSourceStatusPending);
    XCTAssertEqual(source.type, STPSourceTypeiDEAL);
    XCTAssertEqual(source.usage, STPSourceUsageSingleUse);
    XCTAssertNil(source.verification);
    XCTAssertEqualObjects(source.details, response[@"ideal"]);
    XCTAssertNil(source.cardDetails);  // STPSourceCardDetailsTest
    XCTAssertNil(source.sepaDebitDetails);  // STPSourceSEPADebitDetailsTest
    XCTAssertNotEqual(source.allResponseFields, response);  // Verify is copy
    XCTAssertEqualObjects(source.allResponseFields, [response stp_dictionaryByRemovingNulls]);
}

- (void)testDecodingSource_sepa_debit {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONSourceSEPADebit];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(source.stripeID, @"src_18HgGjHNCLa1Vra6Y9TIP6tU");
    XCTAssertNil(source.amount);
    XCTAssertEqualObjects(source.clientSecret, @"src_client_secret_XcBmS94nTg5o0xc9MSliSlDW");
    XCTAssertEqualWithAccuracy([source.created timeIntervalSince1970], 1464803577.0, 1.0);
    XCTAssertEqualObjects(source.currency, @"eur");
    XCTAssertEqual(source.flow, STPSourceFlowNone);
    XCTAssertEqual(source.livemode, NO);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertNil(source.metadata);
#pragma clang diagnostic pop
    XCTAssertEqualObjects(source.owner.name, @"Jenny Rosen");
    XCTAssert(source.owner);  // STPSourceOwnerTest
    XCTAssertNil(source.receiver);  // STPSourceReceiverTest
    XCTAssertNil(source.redirect);  // STPSourceRedirectTest
    XCTAssertEqual(source.status, STPSourceStatusChargeable);
    XCTAssertEqual(source.type, STPSourceTypeSEPADebit);
    XCTAssertEqual(source.usage, STPSourceUsageReusable);
    XCTAssertEqualObjects(source.verification.attemptsRemaining, @5);
    XCTAssertEqual(source.verification.status, STPSourceVerificationStatusPending);
    XCTAssertEqualObjects(source.details, response[@"sepa_debit"]);
    XCTAssertNil(source.cardDetails);  // STPSourceCardDetailsTest
    XCTAssert(source.sepaDebitDetails);  // STPSourceSEPADebitDetailsTest
    XCTAssertNotEqual(source.allResponseFields, response);  // Verify is copy
    XCTAssertEqualObjects(source.allResponseFields, [response stp_dictionaryByRemovingNulls]);
}

#pragma mark - STPPaymentOption Tests

- (NSArray *)possibleAPIResponses {
    return @[[STPTestUtils jsonNamed:STPTestJSONSourceCard],
             [STPTestUtils jsonNamed:STPTestJSONSource3DS],
             [STPTestUtils jsonNamed:STPTestJSONSourceAlipay],
             [STPTestUtils jsonNamed:STPTestJSONSourceBancontact],
             [STPTestUtils jsonNamed:STPTestJSONSourceEPS],
             [STPTestUtils jsonNamed:STPTestJSONSourceGiropay],
             [STPTestUtils jsonNamed:STPTestJSONSourceiDEAL],
             [STPTestUtils jsonNamed:STPTestJSONSourceMultibanco],
             [STPTestUtils jsonNamed:STPTestJSONSourceP24],
             [STPTestUtils jsonNamed:STPTestJSONSourceSEPADebit],
             [STPTestUtils jsonNamed:STPTestJSONSourceSofort]];
}

- (void)testPaymentOptionImage {
    for (NSDictionary *response in [self possibleAPIResponses]) {
        STPSource *source = [STPSource decodedObjectFromAPIResponse:response];

        switch (source.type) {
            case STPSourceTypeCard:
                STPAssertEqualImages(source.image, [STPImageLibrary brandImageForCardBrand:source.cardDetails.brand]);
                break;
            default:
                STPAssertEqualImages(source.image, [STPImageLibrary brandImageForCardBrand:STPCardBrandUnknown]);
                break;
        }
    }
}

- (void)testPaymentOptionTemplateImage {
    for (NSDictionary *response in [self possibleAPIResponses]) {
        STPSource *source = [STPSource decodedObjectFromAPIResponse:response];

        switch (source.type) {
            case STPSourceTypeCard:
                STPAssertEqualImages(source.templateImage, [STPImageLibrary templatedBrandImageForCardBrand:source.cardDetails.brand]);
                break;
            default:
                STPAssertEqualImages(source.templateImage, [STPImageLibrary templatedBrandImageForCardBrand:STPCardBrandUnknown]);
                break;
        }
    }
}

- (void)testPaymentOptionLabel {
    for (NSDictionary *response in [self possibleAPIResponses]) {
        STPSource *source = [STPSource decodedObjectFromAPIResponse:response];

        switch (source.type) {
            case STPSourceTypeBancontact:
                XCTAssertEqualObjects(source.label, @"Bancontact");
                break;
            case STPSourceTypeCard:
                XCTAssertEqualObjects(source.label, @"Visa 5556");
                break;
            case STPSourceTypeGiropay:
                XCTAssertEqualObjects(source.label, @"Giropay");
                break;
            case STPSourceTypeiDEAL:
                XCTAssertEqualObjects(source.label, @"iDEAL");
                break;
            case STPSourceTypeSEPADebit:
                XCTAssertEqualObjects(source.label, @"SEPA Direct Debit");
                break;
            case STPSourceTypeSofort:
                XCTAssertEqualObjects(source.label, @"Sofort");
                break;
            case STPSourceTypeThreeDSecure:
                XCTAssertEqualObjects(source.label, @"3D Secure");
                break;
            case STPSourceTypeAlipay:
                XCTAssertEqualObjects(source.label, @"Alipay");
                break;
            case STPSourceTypeP24:
                XCTAssertEqualObjects(source.label, @"P24");
                break;
            case STPSourceTypeEPS:
                XCTAssertEqualObjects(source.label, @"EPS");
                break;
            case STPSourceTypeMultibanco:
                XCTAssertEqualObjects(source.label, @"Multibanco");
                break;
            case STPSourceTypeWeChatPay:
                XCTAssertEqualObjects(source.label, @"WeChat Pay");
            case STPSourceTypeKlarna:
                XCTAssertEqualObjects(source.label, @"Klarna");
            case STPSourceTypeUnknown:
                XCTAssertEqualObjects(source.label, [STPCard stringFromBrand:STPCardBrandUnknown]);
                break;
        }

    }
}

@end
