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

typedef NS_ENUM(NSInteger, StripeCertificateFailMethod) {
    StripeCertificateFailMethodNoError = 0,
    StripeCertificateFailMethodExpired,
    StripeCertificateFailMethodMismatched,
    StripeCertificateFailMethodRevoked,
    NumStripeCertificateFailMethods
};

@interface STPAPIClient(Failure)
@property(nonatomic, readwrite)NSURL *apiURL;
- (void)setFailureMethod:(StripeCertificateFailMethod)method;
@end

@interface STPCertTest : XCTestCase
@end

@implementation STPCertTest

- (void)testNoError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Token creation"];
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPExamplePublishableKey];
    [client setFailureMethod:StripeCertificateFailMethodNoError];
    [client createTokenWithData:[NSData new]
                             completion:^(STPToken *token, NSError *error) {
                                 [expectation fulfill];
                                 // Note that this API request *will* fail, but it will return error
                                 // messages from the server and not be blocked by local cert checks
                                 XCTAssertNil(token, @"Expected no token");
                                 XCTAssertNotNil(error, @"Expected error");
                             }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCertificateErrorWithMethod:(StripeCertificateFailMethod)method {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Token creation"];
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPExamplePublishableKey];
    [client setFailureMethod:method];
    [client createTokenWithData:[NSData new]
                             completion:^(STPToken *token, NSError *error) {
                                 [expectation fulfill];
                                 XCTAssertNil(token, @"Expected no response");
                                 XCTAssertNotNil(error, @"Expected error");

                                 // Revoked errors are a bit special.
                                 if (method == StripeCertificateFailMethodRevoked) {
                                     XCTAssertEqualObjects(error.domain, StripeDomain, @"Revoked errors specifically are in the Stripe domain");
                                     XCTAssertEqual(error.code, STPConnectionError, @"Revoked errors should generate the right code.");
                                 } else {
                                     XCTAssertEqualObjects(error.domain, @"NSURLErrorDomain", @"Error should be NSURLErrorDomain");
                                     XCTAssertNotNil(error.userInfo[@"NSURLErrorFailingURLPeerTrustErrorKey"],
                                                     @"There should be a secTustRef for Foundation HTTPS errors");
                                 }
                             }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

// These are broken into separate methods to make test reports nicer.

- (void)testExpired {
    [self testCertificateErrorWithMethod:StripeCertificateFailMethodExpired];
}

- (void)testMismatched {
    [self testCertificateErrorWithMethod:StripeCertificateFailMethodMismatched];
}

- (void)testRevoked {
    [self testCertificateErrorWithMethod:StripeCertificateFailMethodRevoked];
}

@end

@implementation STPAPIClient(Failure)

@dynamic apiURL;

- (void)setFailureMethod:(StripeCertificateFailMethod)failureMethod {
    NSURL *url;
    switch (failureMethod) {
            break;
        case StripeCertificateFailMethodExpired:
            url = [NSURL URLWithString:@"https://testssl-expire.disig.sk/index.en.html"];
            break;
        case StripeCertificateFailMethodMismatched:
            url = [NSURL URLWithString:@"https://mismatched.stripe.com"];
            break;
        case StripeCertificateFailMethodRevoked:
            url = [NSURL URLWithString:@"https://revoked.stripe.com:444"];
            break;
        case StripeCertificateFailMethodNoError:
        default:
            break;
    }
    if (url) {
        self.apiURL = url;
    }
}

@end
