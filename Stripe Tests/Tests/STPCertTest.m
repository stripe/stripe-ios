//
//  STPCertTest.m
//  Stripe
//
//  Created by Phillip Cohen on 4/14/14.
//
//

#import "STPAPIClient.h"
#import "Stripe.h"
#import <XCTest/XCTest.h>

NSString *const STPExamplePublishableKey = @"bad_key";

@interface STPAPIClient (Failure)
@property (nonatomic, readwrite) NSURL *apiURL;
@end

@interface STPCertTest : XCTestCase
@end

@implementation STPCertTest

- (void)testNoError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Token creation"];
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPExamplePublishableKey];
    [client createTokenWithData:[NSData new]
                     completion:^(STPToken *token, NSError *error) {
                         [expectation fulfill];
                         // Note that this API request *will* fail, but it will return error
                         // messages from the server and not be blocked by local cert checks
                         XCTAssertNil(token, @"Expected no token");
                         XCTAssertNotNil(error, @"Expected error");
                     }];
    [self waitForExpectationsWithTimeout:10.0f handler:nil];
}

- (void)testExpired {
    [self createTokenWithBaseURL:[NSURL URLWithString:@"https://testssl-expire.disig.sk/index.en.html"]
                      completion:^(STPToken *token, NSError *error) {
                          XCTAssertNil(token, @"Token should be nil.");
                          XCTAssertEqualObjects(error.domain, @"NSURLErrorDomain", @"Error should be NSURLErrorDomain");
                          XCTAssertNotNil(error.userInfo[@"NSURLErrorFailingURLPeerTrustErrorKey"],
                                          @"There should be a secTustRef for Foundation HTTPS errors");
                      }];
}

- (void)testMismatched {
    [self createTokenWithBaseURL:[NSURL URLWithString:@"https://mismatched.stripe.com"]
                      completion:^(STPToken *token, NSError *error) {
                          XCTAssertNil(token, @"Token should be nil.");
                          XCTAssertEqualObjects(error.domain, @"NSURLErrorDomain", @"Error should be NSURLErrorDomain");
                      }];
}

- (void)testRevoked {
    [self createTokenWithBaseURL:[NSURL URLWithString:@"https://revoked.stripe.com:444"]
                      completion:^(STPToken *token, NSError *error) {
                          XCTAssertNil(token, @"Token should be nil.");
                          XCTAssertEqualObjects(error.domain, StripeDomain, @"Revoked errors specifically are in the Stripe domain");
                          XCTAssertEqual(error.code, STPConnectionError, @"Revoked errors should generate the right code.");
                      }];
}

// helper method
- (void)createTokenWithBaseURL:(NSURL *)baseURL completion:(STPCompletionBlock)completion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Token creation"];
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPExamplePublishableKey];
    client.apiURL = baseURL;
    [client createTokenWithData:[NSData new]
                     completion:^(STPToken *token, NSError *error) {
                         [expectation fulfill];
                         completion(token, error);
                     }];

    [self waitForExpectationsWithTimeout:10.0f handler:nil];
}

@end

@implementation STPAPIClient (Failure)
@dynamic apiURL;
@end
