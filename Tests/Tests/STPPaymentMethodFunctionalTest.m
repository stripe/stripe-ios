//
//  STPPaymentMethodFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPTestingAPIClient.h"


@import Stripe;

@interface STPPaymentMethodFunctionalTest : XCTestCase

@end

@implementation STPPaymentMethodFunctionalTest

- (void)setUp {
    [super setUp];
}

- (void)testCreateCardPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    STPPaymentMethodCardParams *card = [STPPaymentMethodCardParams new];
    card.number = @"4242424242424242";
    card.expMonth = @(10);
    card.expYear = @(2022);
    card.cvc = @"100";
    
    STPPaymentMethodAddress *billingAddress = [STPPaymentMethodAddress new];
    billingAddress.city = @"San Francisco";
    billingAddress.country = @"US";
    billingAddress.line1 = @"150 Townsend St";
    billingAddress.line2 = @"4th Floor";
    billingAddress.postalCode = @"94103";
    billingAddress.state = @"CA";
    
    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.address = billingAddress;
    billingDetails.email = @"email@email.com";
    billingDetails.name = @"Isaac Asimov";
    billingDetails.phone = @"555-555-5555";
    
    
    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithCard:card
                                                                 billingDetails:billingDetails
                                                                       metadata:@{@"test_key": @"test_value"}];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method Card create"];
    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod *paymentMethod, NSError *error) {
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(paymentMethod);
                                   XCTAssertNotNil(paymentMethod.stripeId);
                                   XCTAssertNotNil(paymentMethod.created);
                                   XCTAssertFalse(paymentMethod.liveMode);
                                   XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeCard);

                                   // Billing Details
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.email, @"email@email.com");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Isaac Asimov");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.phone, @"555-555-5555");
                                   
                                   // Billing Details Address
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.address.line1, @"150 Townsend St");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.address.line2, @"4th Floor");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.address.city, @"San Francisco");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.address.country, @"US");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.address.state, @"CA");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.address.postalCode, @"94103");
                                   
                                   // Card
                                   XCTAssertEqual(paymentMethod.card.brand, STPCardBrandVisa);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
                                   XCTAssertEqual(paymentMethod.card.checks.cvcCheck, STPPaymentMethodCardCheckResultUnknown);
                                   XCTAssertEqual(paymentMethod.card.checks.addressLine1Check, STPPaymentMethodCardCheckResultUnknown);
                                   XCTAssertEqual(paymentMethod.card.checks.addressPostalCodeCheck, STPPaymentMethodCardCheckResultUnknown);
#pragma clang diagnostic pop
                                   XCTAssertEqualObjects(paymentMethod.card.country, @"US");
                                   XCTAssertEqual(paymentMethod.card.expMonth, 10);
                                   XCTAssertEqual(paymentMethod.card.expYear, 2022);
                                   XCTAssertEqualObjects(paymentMethod.card.funding, @"credit");
                                   XCTAssertEqualObjects(paymentMethod.card.last4, @"4242");
                                   XCTAssertTrue(paymentMethod.card.threeDSecureUsage.supported);
                                   [expectation fulfill];
                               }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCreateBacsPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_z6Ct4bpx0NUjHii0rsi4XZBf00jmM8qA28"];
    
    STPPaymentMethodBacsDebitParams *bacs = [STPPaymentMethodBacsDebitParams new];
    bacs.sortCode = @"108800";
    bacs.accountNumber = @"00012345";
    
    STPPaymentMethodAddress *billingAddress = [STPPaymentMethodAddress new];
    billingAddress.city = @"London";
    billingAddress.country = @"GB";
    billingAddress.line1 = @"Stripe, 7th Floor The Bower Warehouse";
    billingAddress.postalCode = @"EC1V 9NR";
    
    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.address = billingAddress;
    billingDetails.email = @"email@email.com";
    billingDetails.name = @"Isaac Asimov";
    billingDetails.phone = @"555-555-5555";
    
    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithBacsDebit:bacs billingDetails:billingDetails metadata:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method create"];
    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod *paymentMethod, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(paymentMethod);
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeBacsDebit);
        
        // Bacs Debit
        XCTAssertEqualObjects(paymentMethod.bacsDebit.fingerprint, @"UkSG0HfCGxxrja1H");
        XCTAssertEqualObjects(paymentMethod.bacsDebit.last4, @"2345");
        XCTAssertEqualObjects(paymentMethod.bacsDebit.sortCode, @"108800");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testCreateAlipayPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_JBVAMwnBuzCdmsgN34jfxbU700LRiPqVit"];
    
    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithAlipay:[STPPaymentMethodAlipayParams new] billingDetails:nil metadata:nil];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method create"];
    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod *paymentMethod, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(paymentMethod);
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeAlipay);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
