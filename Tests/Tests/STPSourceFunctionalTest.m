//
//  STPSourceFunctionalTest.m
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "Stripe.h"
#import "STPNetworkStubbingTestCase.h"

static NSString *const apiKey = @"pk_test_vOo1umqsYxSrP5UXfOeL3ecm";

@interface STPSourceFunctionalTest : STPNetworkStubbingTestCase
@end

@interface STPAPIClient (WritableURL)
@property (nonatomic, readwrite) NSURL *apiURL;
@end

@implementation STPSourceFunctionalTest

- (void)setUp {
    // self.recordingMode = @YES;
    [super setUp];
}

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
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
        XCTAssertNotNil(source.redirect.url);
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_card {
    STPCardParams *card = [[STPCardParams alloc] init];
    card.number = @"4242 4242 4242 4242";
    card.expMonth = 6;
    card.expYear = 2024;
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
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
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
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
        XCTAssertNotNil(source.redirect.url);
        XCTAssertEqualObjects(source.details[@"bank"], @"ing");
        XCTAssertEqualObjects(source.details[@"statement_descriptor"], @"ORDER AT123");
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_ideal_missingOptionalFields {
    STPSourceParams *params = [STPSourceParams idealParamsWithAmount:1099
                                                                name:nil
                                                           returnURL:@"https://shop.example.com/crtABC"
                                                 statementDescriptor:nil
                                                                bank:nil];

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeIDEAL);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertNil(source.owner.name);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
        XCTAssertNotNil(source.redirect.url);
        XCTAssertNil(source.details[@"bank"]);
        XCTAssertNil(source.details[@"statement_descriptor"]);
        XCTAssertEqualObjects(source.metadata, @{});

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_ideal_emptyOptionalFields {
    STPSourceParams *params = [STPSourceParams idealParamsWithAmount:1099
                                                                name:@""
                                                           returnURL:@"https://shop.example.com/crtABC"
                                                 statementDescriptor:@""
                                                                bank:@""];

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeIDEAL);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertNil(source.owner.name);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
        XCTAssertNotNil(source.redirect.url);
        XCTAssertNil(source.details[@"bank"]);
        XCTAssertNil(source.details[@"statement_descriptor"]);
        XCTAssertEqualObjects(source.metadata, @{});

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
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
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
    card.expYear = 2024;
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

        if (source1.stripeID == nil) {
            XCTFail(@"stripeID of the Card Source is required to create a 3DS source");
            [threeDSExp fulfill];
            return;
        }

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
            XCTAssertEqualObjects(source2.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
            XCTAssertNotNil(source2.redirect.url);
            XCTAssertEqualObjects(source2.metadata, params.metadata);
            [threeDSExp fulfill];
        }];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)skip_testCreateSourceVisaCheckout {
    // The SDK does not have a means of generating Visa Checkout params for testing. Supply your own
    // callId, and the correct publishable key, and you can run this test case
    // manually after removing the `skip_` prefix. It'll log the source's stripeID, and that
    // can be verified in dashboard.
    STPSourceParams *params = [STPSourceParams visaCheckoutParamsWithCallId:@""];
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_"];
    client.apiURL = [NSURL URLWithString:@"https://api.stripe.com/v1"];

    XCTestExpectation *sourceExp = [self expectationWithDescription:@"VCO source created"];
    [client createSourceWithParams:params completion:^(STPSource * _Nullable source, NSError * _Nullable error) {
        [sourceExp fulfill];

        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeCard);
        XCTAssertEqual(source.flow, STPSourceFlowNone);
        XCTAssertEqual(source.status, STPSourceStatusChargeable);
        XCTAssertEqual(source.usage, STPSourceUsageReusable);
        XCTAssertTrue([source.stripeID hasPrefix:@"src_"]);
        NSLog(@"Created a VCO source %@", source.stripeID);
    }];

    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)skip_testCreateSourceMasterpass {
    // The SDK does not have a means of generating Masterpass params for testing. Supply your own
    // cartId & transactionId, and the correct publishable key, and you can run this test case
    // manually after removing the `skip_` prefix. It'll log the source's stripeID, and that
    // can be verified in dashboard.
    STPSourceParams *params = [STPSourceParams masterpassParamsWithCartId:@"" transactionId:@""];
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_"];
    client.apiURL = [NSURL URLWithString:@"https://api.stripe.com/v1"];

    XCTestExpectation *sourceExp = [self expectationWithDescription:@"Masterpass source created"];
    [client createSourceWithParams:params completion:^(STPSource * _Nullable source, NSError * _Nullable error) {
        [sourceExp fulfill];

        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeCard);
        XCTAssertEqual(source.flow, STPSourceFlowNone);
        XCTAssertEqual(source.status, STPSourceStatusChargeable);
        XCTAssertEqual(source.usage, STPSourceUsageSingleUse);
        XCTAssertTrue([source.stripeID hasPrefix:@"src_"]);
        NSLog(@"Created a Masterpass source %@", source.stripeID);
    }];

    [self waitForExpectationsWithTimeout:10.0 handler:nil];
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
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
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
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
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

- (void)testCreateSource_eps {
    STPSourceParams *params = [STPSourceParams epsParamsWithAmount:1099
                                                              name:@"Jenny Rosen"
                                                         returnURL:@"https://shop.example.com/crtABC"
                                               statementDescriptor:@"ORDER AT123"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeEPS);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner.name, params.owner[@"name"]);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
        XCTAssertNotNil(source.redirect.url);
        XCTAssertEqualObjects(source.metadata, params.metadata);
        XCTAssertEqualObjects(source.allResponseFields[@"statement_descriptor"], @"ORDER AT123");

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_eps_no_statement_descriptor {
    STPSourceParams *params = [STPSourceParams epsParamsWithAmount:1099
                                                              name:@"Jenny Rosen"
                                                         returnURL:@"https://shop.example.com/crtABC"
                                               statementDescriptor:nil];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeEPS);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner.name, params.owner[@"name"]);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
        XCTAssertNotNil(source.redirect.url);
        XCTAssertEqualObjects(source.metadata, params.metadata);
        XCTAssertNil(source.allResponseFields[@"statement_descriptor"]);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_multibanco {
    STPSourceParams *params = [STPSourceParams multibancoParamsWithAmount:1099
                                                                returnURL:@"https://shop.example.com/crtABC"
                                                                    email:@"user@example.com"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:apiKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeMultibanco);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
        XCTAssertNotNil(source.redirect.url);
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_wechatPay {
    STPSourceParams *params = [STPSourceParams wechatPayParamsWithAmount:1010
                                                                currency:@"usd"
                                                                   appId:@"wxa0df51ec63e578ce"
                                                     statementDescriptor:nil];

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_live_L4KL0pF017Jgv9hBaWzk4xoB"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeWeChatPay);
        XCTAssertEqual(source.status, STPSourceStatusPending);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertNil(source.redirect);

        STPSourceWeChatPayDetails *wechat = source.weChatPayDetails;
        XCTAssertNotNil(wechat);
        XCTAssertNotNil(wechat.weChatAppURL);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
