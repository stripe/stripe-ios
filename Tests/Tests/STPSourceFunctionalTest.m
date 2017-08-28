//
//  STPSourceFunctionalTest.m
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "Stripe.h"

static NSString *const apiKey = @"pk_test_vOo1umqsYxSrP5UXfOeL3ecm";

@interface STPSourceFunctionalTest : XCTestCase

@end

@implementation STPSourceFunctionalTest

- (void)testCreateSource_bancontact {
    STPSourceParams *params = [STPSourceParams bancontactParamsWithAmount:1099
                                                                     name:@"Jenny Rosen"
                                                                returnURL:@"https://shop.example.com/crtABC"
                                                      statementDescriptor:@"ORDER AT123"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeBancontact);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner.name, params.owner[@"name"]);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC"]);
        XCTAssertNotNil(source.redirect.url);
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

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeBitcoin);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner.email, params.owner[@"email"]);
        XCTAssertEqualObjects(source.metadata, params.metadata);
        XCTAssertNotNil(source.receiver);
        XCTAssertNotNil(source.receiver.address);
        XCTAssertNotNil(source.receiver.amountCharged);
        XCTAssertNotNil(source.receiver.amountReceived);
        XCTAssertNotNil(source.receiver.amountReturned);

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
    card.name = @"Jenny Rosen";
    card.address.line1 = @"123 Fake Street";
    card.address.line2 = @"Apartment 4";
    card.address.city = @"New York";
    card.address.state = @"NY";
    card.address.country = @"USA";
    card.address.postalCode = @"10002";
    STPSourceParams *params = [STPSourceParams cardParamsWithCard:card];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeCard);
        XCTAssertEqualObjects(source.cardDetails.last4, @"4242");
        XCTAssertEqual(source.cardDetails.expMonth, card.expMonth);
        XCTAssertEqual(source.cardDetails.expYear, card.expYear);
        XCTAssertEqualObjects(source.owner.name, card.name);
        STPAddress *address = source.owner.address;
        XCTAssertEqualObjects(address.line1, card.address.line1);
        XCTAssertEqualObjects(address.line2, card.address.line2);
        XCTAssertEqualObjects(address.city, card.address.city);
        XCTAssertEqualObjects(address.state, card.address.state);
        XCTAssertEqualObjects(address.country, card.address.country);
        XCTAssertEqualObjects(address.postalCode, card.address.postalCode);
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_giropay {
    STPSourceParams *params = [STPSourceParams giropayParamsWithAmount:1099
                                                                  name:@"Jenny Rosen"
                                                             returnURL:@"https://shop.example.com/crtABC"
                                                   statementDescriptor:@"ORDER AT123"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeGiropay);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner.name, params.owner[@"name"]);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC"]);
        XCTAssertNotNil(source.redirect.url);
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_ideal {
    STPSourceParams *params = [STPSourceParams idealParamsWithAmount:1099
                                                                name:@"Jenny Rosen"
                                                           returnURL:@"https://shop.example.com/crtABC"
                                                 statementDescriptor:@"ORDER AT123"
                                                                bank:@"ing"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeIDEAL);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner.name, params.owner[@"name"]);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC"]);
        XCTAssertNotNil(source.redirect.url);
        XCTAssertEqualObjects(source.details[@"bank"], @"ing");
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_sepaDebit {
    STPSourceParams *params = [STPSourceParams sepaDebitParamsWithName:@"Jenny Rosen"
                                                                  iban:@"DE89370400440532013000"
                                                          addressLine1:@"Nollendorfstraße 27"
                                                                  city:@"Berlin"
                                                            postalCode:@"10777"
                                                               country:@"DE"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeSEPADebit);
        XCTAssertNil(source.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner.name, params.owner[@"name"]);
        XCTAssertEqualObjects(source.owner.address.city, @"Berlin");
        XCTAssertEqualObjects(source.owner.address.line1, @"Nollendorfstraße 27");
        XCTAssertEqualObjects(source.owner.address.country, @"DE");
        XCTAssertEqualObjects(source.sepaDebitDetails.country, @"DE");
        XCTAssertEqualObjects(source.sepaDebitDetails.last4, @"3000");
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_sepaDebit_NoAddress {
    STPSourceParams *params = [STPSourceParams sepaDebitParamsWithName:@"Jenny Rosen"
                                                                  iban:@"DE89370400440532013000"
                                                          addressLine1:nil
                                                                  city:nil
                                                            postalCode:nil
                                                               country:nil];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeSEPADebit);
        XCTAssertNil(source.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner.name, params.owner[@"name"]);
        XCTAssertNil(source.owner.address.city);
        XCTAssertNil(source.owner.address.line1);
        XCTAssertNil(source.owner.address.country);
        XCTAssertEqualObjects(source.sepaDebitDetails.country, @"DE"); // German IBAN so sepa tells us country here even though we didnt pass it up as owner info
        XCTAssertEqualObjects(source.sepaDebitDetails.last4, @"3000");
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_sofort {
    STPSourceParams *params = [STPSourceParams sofortParamsWithAmount:1099
                                                            returnURL:@"https://shop.example.com/crtABC"
                                                              country:@"DE"
                                                  statementDescriptor:@"ORDER AT11990"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeSofort);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC"]);
        XCTAssertNotNil(source.redirect.url);
        XCTAssertEqualObjects(source.metadata, params.metadata);
        XCTAssertEqualObjects(source.details[@"country"], @"DE");

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_threeDSecure {
    STPCardParams *card = [[STPCardParams alloc] init];
    card.number = @"4000000000003063";
    card.expMonth = 6;
    card.expYear = 2018;
    card.currency = @"usd";
    card.address.line1 = @"123 Fake Street";
    card.address.line2 = @"Apartment 4";
    card.address.city = @"New York";
    card.address.state = @"NY";
    card.address.country = @"USA";
    card.address.postalCode = @"10002";
    STPSourceParams *cardParams = [STPSourceParams cardParamsWithCard:card];

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *cardExp = [self expectationWithDescription:@"Card Source creation"];
    XCTestExpectation *threeDSExp = [self expectationWithDescription:@"3DS Source creation"];
    [client createSourceWithParams:cardParams completion:^(STPSource *source1, NSError *error1) {
        XCTAssertNil(error1);
        XCTAssertNotNil(source1);
        XCTAssertEqual(source1.cardDetails.threeDSecure, STPSourceCard3DSecureStatusRequired);
        [cardExp fulfill];
        STPSourceParams *params = [STPSourceParams threeDSecureParamsWithAmount:1099
                                                                       currency:@"eur"
                                                                      returnURL:@"https://shop.example.com/crtABC"
                                                                           card:source1.stripeID];
        params.metadata = @{ @"foo": @"bar" };
        [client createSourceWithParams:params completion:^(STPSource *source2, NSError *error2) {
            XCTAssertNil(error2);
            XCTAssertNotNil(source2);
            XCTAssertEqual(source2.type, STPSourceTypeThreeDSecure);
            XCTAssertEqualObjects(source2.amount, params.amount);
            XCTAssertEqualObjects(source2.currency, params.currency);
            XCTAssertEqual(source2.redirect.status, STPSourceRedirectStatusPending);
            XCTAssertEqualObjects(source2.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC"]);
            XCTAssertNotNil(source2.redirect.url);
            XCTAssertEqualObjects(source2.metadata, params.metadata);
            [threeDSExp fulfill];
        }];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_alipay {
    STPSourceParams *params = [STPSourceParams alipayParamsWithAmount:1099
                                                             currency:@"usd"
                                                            returnURL:@"https://shop.example.com/crtABC"];

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Alipay Source creation"];

    params.metadata = @{ @"foo": @"bar" };
    [client createSourceWithParams:params completion:^(STPSource *source, NSError *error2) {
        XCTAssertNil(error2);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeAlipay);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC"]);
        XCTAssertNotNil(source.redirect.url);
        XCTAssertEqualObjects(source.metadata, params.metadata);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_p24 {
    STPSourceParams *params = [STPSourceParams p24ParamsWithAmount:1099
                                                          currency:@"eur"
                                                             email:@"user@example.com"
                                                              name:@"Jenny Rosen"
                                                         returnURL:@"https://shop.example.com/crtABC"];

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"P24 Source creation"];

    params.metadata = @{ @"foo": @"bar" };
    [client createSourceWithParams:params completion:^(STPSource *source, NSError *error2) {
        XCTAssertNil(error2);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeP24);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner.email, params.owner[@"email"]);
        XCTAssertEqualObjects(source.owner.name, params.owner[@"name"]);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC"]);
        XCTAssertNotNil(source.redirect.url);
        XCTAssertEqualObjects(source.metadata, params.metadata);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testRetrieveSource_sofort {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    STPSourceParams *params = [STPSourceParams new];
    params.type = STPSourceTypeSofort;
    params.amount = @1099;
    params.currency = @"eur";
    params.redirect = @{@"return_url": @"https://shop.example.com/crtA6B28E1"};
    params.metadata = @{@"foo": @"bar"};
    params.additionalAPIParameters = @{ @"sofort": @{ @"country": @"DE" } };
    XCTestExpectation *createExp = [self expectationWithDescription:@"Source creation"];
    XCTestExpectation *retrieveExp = [self expectationWithDescription:@"Source retrieval"];
    [client createSourceWithParams:params completion:^(STPSource *source1, NSError *error1) {
        XCTAssertNil(error1);
        XCTAssertNotNil(source1);
        [createExp fulfill];
        [client retrieveSourceWithId:source1.stripeID
                        clientSecret:source1.clientSecret
                          completion:^(STPSource *source2, NSError *error2) {
                              XCTAssertNil(error2);
                              XCTAssertNotNil(source2);
                              XCTAssertEqualObjects(source1, source2);
                              [retrieveExp fulfill];
                          }];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
