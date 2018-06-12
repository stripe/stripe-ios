//
//  STPAPIClientTest.m
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPAPIClient+Private.h"
#import "STPFixtures.h"

@interface STPAPIClient (Testing)

@property (nonatomic, readwrite) NSURLSession *urlSession;

@end

@interface STPAPIClientTest : XCTestCase
@end

@implementation STPAPIClientTest

- (void)testSharedClient {
    XCTAssertEqualObjects([STPAPIClient sharedClient], [STPAPIClient sharedClient]);
}

- (void)testSetDefaultPublishableKey {
    [Stripe setDefaultPublishableKey:@"test"];
    STPAPIClient *client = [STPAPIClient sharedClient];
    XCTAssertEqualObjects(client.publishableKey, @"test");
}

- (void)testInitWithPublishableKey {
    STPAPIClient *sut = [[STPAPIClient alloc] initWithPublishableKey:@"pk_foo"];
    NSString *authHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"]].allHTTPHeaderFields[@"Authorization"];
    XCTAssertEqualObjects(authHeader, @"Bearer pk_foo");
}

- (void)testSetPublishableKey {
    STPAPIClient *sut = [[STPAPIClient alloc] initWithPublishableKey:@"pk_foo"];
    NSString *authHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"]].allHTTPHeaderFields[@"Authorization"];
    XCTAssertEqualObjects(authHeader, @"Bearer pk_foo");
    sut.publishableKey = @"pk_bar";
    authHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"]].allHTTPHeaderFields[@"Authorization"];
    XCTAssertEqualObjects(authHeader, @"Bearer pk_bar");
}

- (void)testSetStripeAccount {
    STPAPIClient *sut = [[STPAPIClient alloc] initWithPublishableKey:@"pk_foo"];
    NSString *accountHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"]].allHTTPHeaderFields[@"Stripe-Account"];
    XCTAssertNil(accountHeader);
    sut.stripeAccount = @"acct_123";
    accountHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"]].allHTTPHeaderFields[@"Stripe-Account"];
    XCTAssertEqualObjects(accountHeader, @"acct_123");
}

- (void)testInitWithConfiguration {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.stripeAccount = @"acct_123";

    STPAPIClient *sut = [[STPAPIClient alloc] initWithConfiguration:config];
    XCTAssertEqualObjects(sut.publishableKey, config.publishableKey);
    XCTAssertEqualObjects(sut.stripeAccount, config.stripeAccount);
    NSString *accountHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"]].allHTTPHeaderFields[@"Stripe-Account"];
    XCTAssertEqualObjects(accountHeader, @"acct_123");
}

@end
