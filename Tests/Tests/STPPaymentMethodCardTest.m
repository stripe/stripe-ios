//
//  STPPaymentMethodCardTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAPIClient+Private.h"
#import "STPFixtures.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentMethodCard.h"
#import "STPPaymentMethodCardNetworks.h"
#import "STPTestingAPIClient.h"
#import "STPTestUtils.h"


static NSString *const kCardPaymentIntentClientSecret = @"pi_1H5J4RFY0qyl6XeWFTpgue7g_secret_1SS59M0x65qWMaX2wEB03iwVE";

@interface STPPaymentMethodCard (Testing)

+ (STPCardBrand)brandFromString:(NSString *)string;

@end

@interface STPPaymentMethodCardTest : XCTestCase

@property (nonatomic, readonly, nullable) NSDictionary *cardJSON;

@end

@implementation STPPaymentMethodCardTest

- (void)_retrieveCardJSON:(void (^)(NSDictionary *))completion {
    if (self.cardJSON) {
        completion(self.cardJSON);
    } else {
        STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
        [client retrievePaymentIntentWithClientSecret:kCardPaymentIntentClientSecret
                                               expand:@[@"payment_method"] completion:^(STPPaymentIntent * _Nullable paymentIntent, __unused NSError * _Nullable error) {
            self->_cardJSON = paymentIntent.paymentMethod.card.allResponseFields;
            completion(self.cardJSON);
        }];
    }
}

- (void)testCorrectParsing {
    XCTestExpectation *retrieveJSON = [[XCTestExpectation alloc] initWithDescription:@"Retrieve JSON"];
    [self _retrieveCardJSON:^(NSDictionary *json) {
        STPPaymentMethodCard *card = [STPPaymentMethodCard decodedObjectFromAPIResponse:json];
        XCTAssertNotNil(card, @"Failed to decode JSON");
        [retrieveJSON fulfill];
        XCTAssertEqual(card.brand, STPCardBrandVisa);
        XCTAssertEqualObjects(card.country, @"US");
        XCTAssertNotNil(card.checks);
        XCTAssertEqual(card.expMonth, 7);
        XCTAssertEqual(card.expYear, 2021);
        XCTAssertEqualObjects(card.funding, @"credit");
        XCTAssertEqualObjects(card.last4, @"4242");
        XCTAssertNotNil(card.threeDSecureUsage);
        XCTAssertEqual(card.threeDSecureUsage.supported, YES);
        XCTAssertNotNil(card.networks);
        XCTAssertEqualObjects(card.networks.available, @[@"visa"]);
        XCTAssertNil(card.networks.preferred);
    }];
    [self waitForExpectations:@[retrieveJSON] timeout:STPTestingNetworkRequestTimeout];
}

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];
    
    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:STPTestJSONPaymentMethodCard][@"card"] mutableCopy];
        [response removeObjectForKey:field];
        
        XCTAssertNil([STPPaymentMethodCard decodedObjectFromAPIResponse:response]);
    }
    
    XCTAssertNotNil([STPPaymentMethodCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:STPTestJSONPaymentMethodCard][@"card"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONPaymentMethodCard][@"card"];
    STPPaymentMethodCard *card = [STPPaymentMethodCard decodedObjectFromAPIResponse:response];
    XCTAssertEqual(card.brand, STPCardBrandVisa);
    XCTAssertEqualObjects(card.country, @"US");
    XCTAssertNotNil(card.checks);
    XCTAssertEqual(card.expMonth, 8);
    XCTAssertEqual(card.expYear, 2020);
    XCTAssertEqualObjects(card.funding, @"credit");
    XCTAssertEqualObjects(card.last4, @"4242");
    XCTAssertEqualObjects(card.fingerprint, @"6gVyxfIhqc8Z0g0X");
    XCTAssertNotNil(card.threeDSecureUsage);
    XCTAssertEqual(card.threeDSecureUsage.supported, YES);
    XCTAssertNotNil(card.wallet);
}

- (void)testBrandFromString {
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"visa"], STPCardBrandVisa);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"VISA"], STPCardBrandVisa);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"amex"], STPCardBrandAmex);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"AMEX"], STPCardBrandAmex);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"mastercard"], STPCardBrandMasterCard);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"MASTERCARD"], STPCardBrandMasterCard);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"discover"], STPCardBrandDiscover);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"DISCOVER"], STPCardBrandDiscover);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"jcb"], STPCardBrandJCB);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"JCB"], STPCardBrandJCB);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"diners"], STPCardBrandDinersClub);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"DINERS"], STPCardBrandDinersClub);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"unionpay"], STPCardBrandUnionPay);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"UNIONPAY"], STPCardBrandUnionPay);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"unknown"], STPCardBrandUnknown);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"UNKNOWN"], STPCardBrandUnknown);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"garbage"], STPCardBrandUnknown);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"GARBAGE"], STPCardBrandUnknown);
}

@end
