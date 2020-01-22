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
#import "STPEphemeralKey.h"

@interface STPAPIClient (Testing)

@property (nonatomic, readwrite) NSURLSession *urlSession;

- (NSDictionary<NSString *, NSString *> *)authorizationHeaderUsingEphemeralKey:(STPEphemeralKey *)ephemeralKey;

@end

@interface STPAPIClientTest : XCTestCase
@end

@implementation STPAPIClientTest

- (void)testSharedClient {
    XCTAssertEqualObjects([STPAPIClient sharedClient], [STPAPIClient sharedClient]);
}

- (void)testSetDefaultPublishableKey {
    [Stripe setDefaultPublishableKey:@"test"];
    STPAPIClient *clientInitializedAfter = [STPAPIClient new];
    STPAPIClient *sharedClient = [STPAPIClient sharedClient];
    XCTAssertEqualObjects(sharedClient.publishableKey, @"test");
    XCTAssertEqualObjects(clientInitializedAfter.publishableKey, @"test");
    
    // Setting the STPAPIClient instance overrides Stripe.defaultPublishableKey...
    sharedClient.publishableKey = @"test2";
    XCTAssertEqualObjects(sharedClient.publishableKey, @"test2");
    
    // ...while Stripe.defaultPublishableKey remains the same
    XCTAssertEqualObjects(Stripe.defaultPublishableKey, @"test");
}

- (void)testInitWithPublishableKey {
    STPAPIClient *sut = [[STPAPIClient alloc] initWithPublishableKey:@"pk_foo"];
    NSString *authHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"] additionalHeaders:nil].allHTTPHeaderFields[@"Authorization"];
    XCTAssertEqualObjects(authHeader, @"Bearer pk_foo");
}

- (void)testSetPublishableKey {
    STPAPIClient *sut = [[STPAPIClient alloc] initWithPublishableKey:@"pk_foo"];
    NSString *authHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"] additionalHeaders:nil].allHTTPHeaderFields[@"Authorization"];
    XCTAssertEqualObjects(authHeader, @"Bearer pk_foo");
    sut.publishableKey = @"pk_bar";
    authHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"] additionalHeaders:nil].allHTTPHeaderFields[@"Authorization"];
    XCTAssertEqualObjects(authHeader, @"Bearer pk_bar");
}

- (void)testEphemeralKeyOverwritesHeader {
    STPAPIClient *sut = [[STPAPIClient alloc] initWithPublishableKey:@"pk_foo"];
    STPEphemeralKey *ephemeralKey = [STPFixtures ephemeralKey];
    NSDictionary *additionalHeaders = [sut authorizationHeaderUsingEphemeralKey:ephemeralKey];
    NSString *authHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"] additionalHeaders:additionalHeaders].allHTTPHeaderFields[@"Authorization"];
    XCTAssertEqualObjects(authHeader, [@"Bearer " stringByAppendingString:ephemeralKey.secret]);
}

- (void)testSetStripeAccount {
    STPAPIClient *sut = [[STPAPIClient alloc] initWithPublishableKey:@"pk_foo"];
    NSString *accountHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"] additionalHeaders:nil].allHTTPHeaderFields[@"Stripe-Account"];
    XCTAssertNil(accountHeader);
    sut.stripeAccount = @"acct_123";
    accountHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"] additionalHeaders:nil].allHTTPHeaderFields[@"Stripe-Account"];
    XCTAssertEqualObjects(accountHeader, @"acct_123");
}

- (void)testInitWithConfiguration {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    config.publishableKey = @"pk_123";
    config.stripeAccount = @"acct_123";

    STPAPIClient *sut = [[STPAPIClient alloc] initWithConfiguration:config];
    XCTAssertEqualObjects(sut.publishableKey, config.publishableKey);
    XCTAssertEqualObjects(sut.stripeAccount, config.stripeAccount);
#pragma clang diagnostic pop

    NSString *accountHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"] additionalHeaders:nil].allHTTPHeaderFields[@"Stripe-Account"];
    XCTAssertEqualObjects(accountHeader, @"acct_123");
}

- (void)testSetAppInfo {
    STPAPIClient *sut = [[STPAPIClient alloc] initWithPublishableKey:@"pk_foo"];
    sut.appInfo = [[STPAppInfo alloc] initWithName:@"MyAwesomeLibrary" partnerId:@"pp_partner_1234" version:@"1.2.34" url:@"https://myawesomelibrary.info"];
    NSString *userAgentHeader = [sut configuredRequestForURL:[NSURL URLWithString:@"https://www.stripe.com"] additionalHeaders:nil].allHTTPHeaderFields[@"X-Stripe-User-Agent"];
    NSDictionary *userAgentHeaderDict = [NSJSONSerialization JSONObjectWithData:[userAgentHeader dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    XCTAssertEqualObjects(userAgentHeaderDict[@"name"], @"MyAwesomeLibrary");
    XCTAssertEqualObjects(userAgentHeaderDict[@"partner_id"], @"pp_partner_1234");
    XCTAssertEqualObjects(userAgentHeaderDict[@"version"], @"1.2.34");
    XCTAssertEqualObjects(userAgentHeaderDict[@"url"], @"https://myawesomelibrary.info");
}

@end
