//
//  STPCertTest.m
//  Stripe
//
//  Created by Phillip Cohen on 4/14/14.
//
//

@import XCTest;

#import "STPAPIClient.h"
#import "STPAPIClient+Private.h"
#import "Stripe.h"

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
    [client createTokenWithParameters:@{}
                           completion:^(STPToken *token, NSError *error) {
                               [expectation fulfill];
                               // Note that this API request *will* fail, but it will return error
                               // messages from the server and not be blocked by local cert checks
                               XCTAssertNil(token, @"Expected no token");
                               XCTAssertNotNil(error, @"Expected error");
                           }];
    [self waitForExpectationsWithTimeout:20.0f handler:nil];
}

- (void)testExpired {
    [self createTokenWithBaseURL:[NSURL URLWithString:@"https://testssl-expire-r2i2.disig.sk/index.en.html"]
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

// helper method
- (void)createTokenWithBaseURL:(NSURL *)baseURL completion:(STPTokenCompletionBlock)completion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Token creation"];
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPExamplePublishableKey];
    client.apiURL = baseURL;
    [client createTokenWithParameters:@{}
                           completion:^(STPToken *token, NSError *error) {
                               [expectation fulfill];
                               completion(token, error);
                           }];
    [self waitForExpectationsWithTimeout:20.0f handler:nil];
}

@end

@implementation STPAPIClient (Failure)
@dynamic apiURL;
@end
