//
//  STPSourceFunctionalTest.m
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "Stripe.h"

@interface STPSourceFunctionalTest : XCTestCase

@end

@implementation STPSourceFunctionalTest

- (void)testCreateSource_bancontact {
    STPSourceParams *params = [STPSourceParams bancontactParamsWithAmount:1099
                                                                     name:@"Jenny Rosen"
                                                                returnURL:@"https://shop.foo.com/crtABC"
                                                      statementDescriptor:@"ORDER AT123"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqualObjects(source.type, @"bancontact");
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner[@"name"], params.owner[@"name"]);
        XCTAssertEqualObjects(source.redirect[@"return_url"], params.redirect[@"return_url"]);
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_bitcoin {
    STPSourceParams *params = [STPSourceParams bitcoinParamsWithAmount:1000
                                                              currency:@"usd"
                                                                 email:@"user@example.com"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqualObjects(source.type, @"bitcoin");
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner[@"email"], params.owner[@"email"]);
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_card {
    STPCardParams *card = [[STPCardParams alloc] init];
    card.number = @"4242 4242 4242 4242";
    card.expMonth = 6;
    card.expYear = 2018;
    card.currency = @"usd";
    card.addressLine1 = @"123 Fake Street";
    card.addressLine2 = @"Apartment 4";
    card.addressCity = @"New York";
    card.addressState = @"NY";
    card.addressCountry = @"USA";
    card.addressZip = @"10002";
    STPSourceParams *params = [STPSourceParams cardParamsWithCard:card];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqualObjects(source.type, @"card");
        NSDictionary *cardDict = source.allResponseFields[@"card"];
        XCTAssertEqualObjects(cardDict[@"last4"], @"4242");
        XCTAssertEqualObjects(cardDict[@"cvc"], card.cvc);
        XCTAssertEqualObjects(cardDict[@"exp_month"], @(card.expMonth));
        XCTAssertEqualObjects(cardDict[@"exp_year"], @(card.expYear));
        NSDictionary *addressDict = source.owner[@"address"];
        XCTAssertEqualObjects(addressDict[@"line1"], card.addressLine1);
        XCTAssertEqualObjects(addressDict[@"line2"], card.addressLine2);
        XCTAssertEqualObjects(addressDict[@"city"], card.addressCity);
        XCTAssertEqualObjects(addressDict[@"state"], card.addressState);
        XCTAssertEqualObjects(addressDict[@"country"], card.addressCountry);
        XCTAssertEqualObjects(addressDict[@"postal_code"], card.addressZip);
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_giropay {
    STPSourceParams *params = [STPSourceParams giropayParamsWithAmount:1099
                                                                  name:@"Jenny Rosen"
                                                             returnURL:@"https://shop.foo.com/crtABC"
                                                   statementDescriptor:@"ORDER AT123"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqualObjects(source.type, @"giropay");
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner[@"name"], params.owner[@"name"]);
        XCTAssertEqualObjects(source.redirect[@"return_url"], params.redirect[@"return_url"]);
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_ideal {
    STPSourceParams *params = [STPSourceParams idealParamsWithAmount:1099
                                                                name:@"Jenny Rosen"
                                                           returnURL:@"https://shop.foo.com/crtABC"
                                                 statementDescriptor:@"ORDER AT123"
                                                                bank:@"ing"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqualObjects(source.type, @"ideal");
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner[@"name"], params.owner[@"name"]);
        XCTAssertEqualObjects(source.redirect[@"return_url"], params.redirect[@"return_url"]);
        XCTAssertEqualObjects(source.allResponseFields[@"ideal"][@"bank"], @"ing");
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_sepaDebit {
    STPSourceParams *params = [STPSourceParams sepaDebitParamsWithAmount:1099
                                                                    name:@"Jenny Rosen"
                                                                    iban:@"DE89370400440532013000"
                                                                 address:@{
                                                                           @"line1": @"Nollendorfstraße 27",
                                                                           @"city": @"Berlin",
                                                                           @"postal_code": @"10777",
                                                                           @"country": @"DE"
                                                                           }];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqualObjects(source.type, @"sepa_debit");
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner[@"name"], params.owner[@"name"]);
        XCTAssertEqualObjects(source.owner[@"address"][@"city"], @"Berlin");
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_sofort {
    STPSourceParams *params = [STPSourceParams sofortParamsWithAmount:1099
                                                            returnURL:@"https://shop.foo.com/crtA6B28E1"
                                                              country:@"DE"
                                                  statementDescriptor:@"ORDER AT11990"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqualObjects(source.type, @"sofort");
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.redirect[@"return_url"], params.redirect[@"return_url"]);
        XCTAssertEqualObjects(source.metadata, params.metadata);
        XCTAssertEqualObjects(source.allResponseFields[@"sofort"][@"country"], @"DE");

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_threeDSecure {
    STPCardParams *card = [[STPCardParams alloc] init];
    card.number = @"4242 4242 4242 4242";
    card.expMonth = 6;
    card.expYear = 2018;
    card.currency = @"usd";
    card.addressLine1 = @"123 Fake Street";
    card.addressLine2 = @"Apartment 4";
    card.addressCity = @"New York";
    card.addressState = @"NY";
    card.addressCountry = @"USA";
    card.addressZip = @"10002";
    STPSourceParams *cardParams = [STPSourceParams cardParamsWithCard:card];

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    XCTestExpectation *cardExp = [self expectationWithDescription:@"Card Source creation"];
    XCTestExpectation *threeDSExp = [self expectationWithDescription:@"3DS Source creation"];
    [client createSourceWithParams:cardParams completion:^(STPSource *source1, NSError *error1) {
        XCTAssertNil(error1);
        XCTAssertNotNil(source1);
        [cardExp fulfill];
        STPSourceParams *params = [STPSourceParams threeDSecureParamsWithAmount:1099
                                                                       currency:@"eur"
                                                                      returnURL:@"https://shop.foo.com/crt123"
                                                                           card:source1.stripeID];
        params.metadata = @{ @"foo": @"bar" };
        [client createSourceWithParams:params completion:^(STPSource *source2, NSError *error2) {
            XCTAssertNil(error2);
            XCTAssertNotNil(source2);
            XCTAssertEqualObjects(source2.type, @"three_d_secure");
            XCTAssertEqualObjects(source2.amount, params.amount);
            XCTAssertEqualObjects(source2.currency, params.currency);
            XCTAssertEqualObjects(source2.redirect[@"return_url"], params.redirect[@"return_url"]);
            XCTAssertEqualObjects(source2.metadata, params.metadata);
            [threeDSExp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
