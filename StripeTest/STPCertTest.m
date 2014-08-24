//
//  STPCertTest.m
//  Stripe
//
//  Created by Phillip Cohen on 4/14/14.
//
//

#import "Stripe.h"
#import "STPCertTest.h"

#define EXAMPLE_STRIPE_PUBLISHABLE_KEY @"pk_test_9eiBtT0PmkdfvFiHBpktXKsr"

typedef NS_ENUM(NSInteger, StripeCertificateFailMethod) {
    StripeCertificateFailMethodNoError = 0,
    StripeCertificateFailMethodExpired,
    StripeCertificateFailMethodMismatched,
    StripeCertificateFailMethodRevoked,
    NumStripeCertificateFailMethods
};

@interface FailableStripe : Stripe
+ (void)setFailureMethod:(StripeCertificateFailMethod)method;
@end

@implementation STPCertTest

- (void)testNoError
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [FailableStripe setFailureMethod:StripeCertificateFailMethodNoError];
    [FailableStripe createTokenWithCard:[self dummyCard]
                         publishableKey:EXAMPLE_STRIPE_PUBLISHABLE_KEY
                             completion:^(STPToken *token, NSError *error) {
                                 // Note that this API request *will* fail, but it will return error
                                 // messages from the server and not be blocked by local cert checks
                                 XCTAssertNil(token, @"Expected no token");
                                 XCTAssertNotNil(error, @"Expected error");
                                 dispatch_semaphore_signal(semaphore);
                             }];

    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)testCertificateErrorWithMethod:(StripeCertificateFailMethod)method
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [FailableStripe setFailureMethod:method];
    [FailableStripe createTokenWithCard:[self dummyCard]
                         publishableKey:EXAMPLE_STRIPE_PUBLISHABLE_KEY
                             completion:^(STPToken *token, NSError *error) {
                                 XCTAssertNil(token, @"Expected no response");
                                 XCTAssertNotNil(error, @"Expected error");

                                 // Revoked errors are a bit special.
                                 if (method == StripeCertificateFailMethodRevoked) {
                                     XCTAssertEqualObjects(error.domain, StripeDomain, @"Revoked errors specifically are in the Stripe domain");
                                     XCTAssertEqual(error.code, STPConnectionError, @"Revoked errors should generate the right code.");
                                 } else {
                                     XCTAssertEqualObjects(error.domain, @"NSURLErrorDomain", @"Error should be NSURLErrorDomain");
                                     XCTAssertNotNil(error.userInfo[@"NSURLErrorFailingURLPeerTrustErrorKey"], @"There should be a secTustRef for Foundation HTTPS errors");
                                 }
                                 dispatch_semaphore_signal(semaphore);
                             }];

    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

// These are broken into separate methods to make test reports nicer.

- (void)testExpired
{
    [self testCertificateErrorWithMethod:StripeCertificateFailMethodExpired];
}

- (void)testMismatched
{
    [self testCertificateErrorWithMethod:StripeCertificateFailMethodMismatched];
}

- (void)testRevoked
{
    [self testCertificateErrorWithMethod:StripeCertificateFailMethodRevoked];
}

- (STPCard *)dummyCard
{
    STPCard *card = [[STPCard alloc] init];
    card.number = @"4242424242424242";
    card.expMonth = 12;
    card.expYear = 2020;
    return card;
}

@end

#pragma mark FailableStripe

@interface Stripe ()
+ (NSURL *)apiURL;
@end

@implementation FailableStripe

static StripeCertificateFailMethod failureMethod;

+ (NSURL *)apiURL
{
    switch (failureMethod) {
        case StripeCertificateFailMethodNoError:
            return [Stripe apiURL];
        case StripeCertificateFailMethodExpired:
            return [NSURL URLWithString:@"https://testssl-expire.disig.sk/index.en.html"];
        case StripeCertificateFailMethodMismatched:
            return [NSURL URLWithString:@"https://mismatched.stripe.com"];
        case StripeCertificateFailMethodRevoked:
            return [NSURL URLWithString:@"https://revoked.stripe.com:444"];
        default:
            [NSException raise:@"InvalidFailureMethod" format:@""];
    }

    return nil;
}

+ (void)setFailureMethod:(StripeCertificateFailMethod)method
{
    failureMethod = method;
}

@end
