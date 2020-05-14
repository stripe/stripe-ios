//
//  STPPaymentMethodTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentMethod+Private.h"
#import "STPTestUtils.h"
#import "STPFixtures.h"

@interface STPPaymentMethodTest : XCTestCase

@end

@implementation STPPaymentMethodTest

#pragma mark - STPPaymentMethodType Tests

- (void)testTypeFromString {
    XCTAssertEqual([STPPaymentMethod typeFromString:@"au_becs_debit"], STPPaymentMethodTypeAUBECSDebit);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"AU_BECS_DEBIT"], STPPaymentMethodTypeAUBECSDebit);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"BACS_DEBIT"], STPPaymentMethodTypeBacsDebit);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"bacs_debit"], STPPaymentMethodTypeBacsDebit);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"BACS_DEBIT"], STPPaymentMethodTypeBacsDebit);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"card"], STPPaymentMethodTypeCard);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"CARD"], STPPaymentMethodTypeCard);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"ideal"], STPPaymentMethodTypeiDEAL);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"IDEAL"], STPPaymentMethodTypeiDEAL);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"fpx"], STPPaymentMethodTypeFPX);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"FPX"], STPPaymentMethodTypeFPX);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"sepa_debit"], STPPaymentMethodTypeSEPADebit);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"SEPA_DEBIT"], STPPaymentMethodTypeSEPADebit);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"card_present"], STPPaymentMethodTypeCardPresent);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"CARD_PRESENT"], STPPaymentMethodTypeCardPresent);
    XCTAssertEqual([STPPaymentMethod typeFromString:@"unknown_string"], STPPaymentMethodTypeUnknown);
}

- (void)testTypesFromStrings {
    NSArray *rawTypes = @[@"card", @"ideal", @"card_present", @"fpx", @"sepa_debit", @"bacs_debit", @"au_becs_debit"];
    NSArray *expectedTypes = @[@(STPPaymentMethodTypeCard), @(STPPaymentMethodTypeiDEAL), @(STPPaymentMethodTypeCardPresent), @(STPPaymentMethodTypeFPX), @(STPPaymentMethodTypeSEPADebit), @(STPPaymentMethodTypeBacsDebit), @(STPPaymentMethodTypeAUBECSDebit)];
    XCTAssertEqualObjects([STPPaymentMethod typesFromStrings:rawTypes], expectedTypes);
}

- (void)testStringFromType {
    NSArray<NSNumber *> *values = @[
                                    @(STPPaymentMethodTypeCard),
                                    @(STPPaymentMethodTypeiDEAL),
                                    @(STPPaymentMethodTypeCardPresent),
                                    @(STPPaymentMethodTypeFPX),
                                    @(STPPaymentMethodTypeSEPADebit),
                                    @(STPPaymentMethodTypeBacsDebit),
                                    @(STPPaymentMethodTypeAUBECSDebit),
                                    @(STPPaymentMethodTypeGiropay),
                                    @(STPPaymentMethodTypeUnknown),
                                    ];
    for (NSNumber *typeNumber in values) {
        STPPaymentMethodType type = (STPPaymentMethodType)[typeNumber integerValue];
        NSString *string = [STPPaymentMethod stringFromType:type];
        
        switch (type) {
            case STPPaymentMethodTypeCard:
                XCTAssertEqualObjects(string, @"card");
                break;
            case STPPaymentMethodTypeiDEAL:
                XCTAssertEqualObjects(string, @"ideal");
                break;
            case STPPaymentMethodTypeCardPresent:
                XCTAssertEqualObjects(string, @"card_present");
                break;
            case STPPaymentMethodTypeFPX:
                XCTAssertEqualObjects(string, @"fpx");
                break;
            case STPPaymentMethodTypeSEPADebit:
                XCTAssertEqualObjects(string, @"sepa_debit");
                break;
            case STPPaymentMethodTypeBacsDebit:
                XCTAssertEqualObjects(string, @"bacs_debit");
                break;
            case STPPaymentMethodTypeAUBECSDebit:
                XCTAssertEqualObjects(string, @"au_becs_debit");
                break;
            case STPPaymentMethodTypeGiropay:
                XCTAssertEqualObjects(string, @"giropay");
                break;
            case STPPaymentMethodTypePrzelewy24:
                XCTAssertEqualObjects(string, @"p24");
                break;
            case STPPaymentMethodTypeBancontact:
                XCTAssertEqualObjects(string, @"bancontact");
                break;
            case STPPaymentMethodTypeUnknown:
                XCTAssertNil(string);
                break;
        }
    }
}


#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSDictionary *fullJson = [STPTestUtils jsonNamed:STPTestJSONPaymentMethodCard];
    
    XCTAssertNotNil([STPPaymentMethod decodedObjectFromAPIResponse:fullJson], @"can decode with full json");
    
    NSArray<NSString *> *requiredFields = @[@"id"];
    
    for (NSString *field in requiredFields) {
        NSMutableDictionary *partialJson = [fullJson mutableCopy];
        
        XCTAssertNotNil(partialJson[field], @"json should contain %@", field);
        [partialJson removeObjectForKey:field];
        
        XCTAssertNil([STPPaymentIntent decodedObjectFromAPIResponse:partialJson], @"should not decode without %@", field);
    }
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONPaymentMethodCard];
    STPPaymentMethod *paymentMethod = [STPPaymentMethod decodedObjectFromAPIResponse:response];
    
    XCTAssertEqualObjects(paymentMethod.stripeId, @"pm_123456789");
    XCTAssertEqualObjects(paymentMethod.created, [NSDate dateWithTimeIntervalSince1970:123456789]);
    XCTAssertEqual(paymentMethod.liveMode, NO);
    XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeCard);
    XCTAssertNotNil(paymentMethod.billingDetails);
    XCTAssertNotNil(paymentMethod.card);
    XCTAssertNil(paymentMethod.customerId);
    XCTAssertEqualObjects(paymentMethod.metadata, @{@"order_id": @"123456789"});
    
    XCTAssertNotEqual(paymentMethod.allResponseFields, response, @"should have own copy of fields");
    XCTAssertEqualObjects(paymentMethod.allResponseFields, response, @"fields values should match");
}

@end
