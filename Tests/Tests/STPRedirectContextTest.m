//
//  STPRedirectContextTest.m
//  Stripe
//
//  Created by Ben Guo on 4/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <SafariServices/SafariServices.h>
#import <XCTest/XCTest.h>
#import "NSError+Stripe.h"
#import "NSURLComponents+Stripe.h"
#import "STPFixtures.h"
#import "STPRedirectContext.h"
#import "STPURLCallbackHandler.h"

@interface STPSource (Testing)

//@property (nonatomic, nonnull) NSString *stripeID;
//@property (nonatomic, nullable) NSNumber *amount;
//@property (nonatomic, nullable) NSString *clientSecret;
//@property (nonatomic, nullable) NSDate *created;
//@property (nonatomic, nullable) NSString *currency;
@property (nonatomic, readwrite) STPSourceFlow flow;
//@property (nonatomic) BOOL livemode;
//@property (nonatomic, nullable) NSDictionary *metadata;
//@property (nonatomic, nullable) STPSourceOwner *owner;
//@property (nonatomic, nullable) STPSourceReceiver *receiver;
//@property (nonatomic, nullable) STPSourceRedirect *redirect;
@property (nonatomic, readwrite) STPSourceStatus status;
//@property (nonatomic) STPSourceType type;
//@property (nonatomic) STPSourceUsage usage;
//@property (nonatomic, nullable) STPSourceVerification *verification;
//@property (nonatomic, nullable) NSDictionary *details;
//@property (nonatomic, nullable) STPSourceCardDetails *cardDetails;
//@property (nonatomic, nullable) STPSourceSEPADebitDetails *sepaDebitDetails;
//@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@interface STPRedirectContext (Testing)

- (void)unsubscribeFromNotifications;
- (void)dismissPresentedViewController;

@end

@interface STPRedirectContextTest : XCTestCase

@end

@implementation STPRedirectContextTest

- (void)testInitWithSourceCompletion_nonRedirectSource {
    // Should return `nil` for non-redirect source
    STPSource *source = [STPFixtures cardSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
    XCTAssertNil(context);
}

- (void)testInitWithSourceCompletion_nonRedirectFlow {
    // Should return `nil` for source with non-redirect flow
    NSArray *sourceFlows = @[
                             @(STPSourceFlowNone),
                             @(STPSourceFlowCodeVerification),
                             @(STPSourceFlowReceiver),
                             @(STPSourceFlowUnknown)
                             ];

    for (NSNumber *flowNumber in sourceFlows) {
        STPSource *source = [STPFixtures iDEALSource];
        source.flow = flowNumber.integerValue;

        STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
        XCTAssertNil(context);
    }
}

- (void)testInitWithSourceCompletion_statusNotPending {
    // Should return `nil` for source with non-pending status
    NSArray *sourceStatuses = @[
                                @(STPSourceStatusChargeable),
                                @(STPSourceStatusConsumed),
                                @(STPSourceStatusCanceled),
                                @(STPSourceStatusFailed),
                                @(STPSourceStatusUnknown)
                                ];

    for (NSNumber *statusNumber in sourceStatuses) {
        STPSource *source = [STPFixtures iDEALSource];
        source.status = statusNumber.integerValue;

        STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
        XCTAssertNil(context);
    }
}

- (void)testInitWithSourceCompletion_missingReturnURL {
    // Should return `nil` for source with missing return URL
    STPSource *source = [STPFixtures iDEALSource];
    source.redirect.returnURL = nil;

    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
    XCTAssertNil(context);
}

- (void)testInitWithSourceCompletion_validRedirectSource {
    // Should return object for valid redirect source
    STPSource *source = [STPFixtures iDEALSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
        XCTFail("Should not have called completion: sourceID=%@, clientSecret=%@, error=%@", sourceID, clientSecret, error);
    }];
    XCTAssert(context);
}

/**
 After starting a SafariViewController redirect flow,
 when the shared URLCallbackHandler is called with a valid URL,
 RedirectContext's completion block and dismiss method should be called.
 */
- (void)testSafariViewControllerRedirectFlow_callbackHandlerCalledValidURL {
    id mockVC = OCMClassMock([UIViewController class]);
    STPSource *source = [STPFixtures iDEALSource];
    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
        XCTAssertEqualObjects(sourceID, source.stripeID);
        XCTAssertEqualObjects(clientSecret, source.clientSecret);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    id sut = OCMPartialMock(context);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    BOOL(^checker)(id) = ^BOOL(id vc) {
        if ([vc isKindOfClass:[SFSafariViewController class]]) {
            NSURL *url = source.redirect.returnURL;
            NSURLComponents *comps = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
            [comps setStp_queryItemsDictionary:@{@"source": source.stripeID,
                                                 @"client_secret": source.clientSecret}];
            [[STPURLCallbackHandler shared] handleURLCallback:comps.URL];
            return YES;
        }
        return NO;
    };
    OCMVerify([mockVC presentViewController:[OCMArg checkWithBlock:checker]
                                   animated:YES
                                 completion:[OCMArg any]]);
    OCMVerify([sut unsubscribeFromNotifications]);
    OCMVerify([sut dismissPresentedViewController]);

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 After starting a SafariViewController redirect flow,
 when the shared URLCallbackHandler is called with an invalid URL,
 RedirectContext's completion block and dismiss method should be called.
 */
- (void)testSafariViewControllerRedirectFlow_callbackHandlerCalledInvalidURL {
    id mockVC = OCMClassMock([UIViewController class]);
    STPSource *source = [STPFixtures iDEALSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
        XCTFail(@"completion called");
    }];
    id sut = OCMPartialMock(context);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    BOOL(^checker)(id) = ^BOOL(id vc) {
        if ([vc isKindOfClass:[SFSafariViewController class]]) {
            NSURL *url = [NSURL URLWithString:@"my-app://some_path"];
            [[STPURLCallbackHandler shared] handleURLCallback:url];
            return YES;
        }
        return NO;
    };
    OCMVerify([mockVC presentViewController:[OCMArg checkWithBlock:checker]
                                   animated:YES
                                 completion:[OCMArg any]]);
    OCMReject([sut unsubscribeFromNotifications]);
    OCMReject([sut dismissPresentedViewController]);
}

/**
 After starting a SafariViewController redirect flow,
 when SafariViewController finishes, RedirectContext's completion block
 should be called.
 */
- (void)testSafariViewControllerRedirectFlow_didFinish {
    id mockVC = OCMClassMock([UIViewController class]);
    STPSource *source = [STPFixtures iDEALSource];
    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
        XCTAssertEqualObjects(sourceID, source.stripeID);
        XCTAssertEqualObjects(clientSecret, source.clientSecret);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    id sut = OCMPartialMock(context);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    BOOL(^checker)(id) = ^BOOL(id vc) {
        if ([vc isKindOfClass:[SFSafariViewController class]]) {
            SFSafariViewController *sfvc = (SFSafariViewController *)vc;
            [sfvc.delegate safariViewControllerDidFinish:sfvc];
            return YES;
        }
        return NO;
    };
    OCMVerify([mockVC presentViewController:[OCMArg checkWithBlock:checker]
                                   animated:YES
                                 completion:[OCMArg any]]);
    OCMVerify([sut unsubscribeFromNotifications]);
    // dismiss should not be called – SafariVC dismisses itself when Done is tapped
    OCMReject([sut dismissPresentedViewController]);

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 After starting a SafariViewController redirect flow,
 when SafariViewController fails to load, RedirectContext's completion block
 and dismiss method should be called.
 */
- (void)testSafariViewControllerRedirectFlow_failedToLoad {
    id mockVC = OCMClassMock([UIViewController class]);
    STPSource *source = [STPFixtures iDEALSource];
    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
        XCTAssertEqualObjects(sourceID, source.stripeID);
        XCTAssertEqualObjects(clientSecret, source.clientSecret);
        NSError *expectedError = [NSError stp_genericConnectionError];
        XCTAssertEqualObjects(error, expectedError);
        [exp fulfill];
    }];
    id sut = OCMPartialMock(context);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    BOOL(^checker)(id) = ^BOOL(id vc) {
        if ([vc isKindOfClass:[SFSafariViewController class]]) {
            SFSafariViewController *sfvc = (SFSafariViewController *)vc;
            [sfvc.delegate safariViewController:sfvc didCompleteInitialLoad:NO];
            return YES;
        }
        return NO;
    };
    OCMVerify([mockVC presentViewController:[OCMArg checkWithBlock:checker]
                                   animated:YES
                                 completion:[OCMArg any]]);
    OCMVerify([sut unsubscribeFromNotifications]);
    OCMVerify([sut dismissPresentedViewController]);

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 After starting a SafariViewController redirect flow,
 when the RedirectContext is cancelled, its dismiss method should be called.
 */
- (void)testSafariViewControllerRedirectFlow_cancel {
    id mockVC = OCMClassMock([UIViewController class]);
    STPSource *source = [STPFixtures iDEALSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
        XCTFail(@"completion called");
    }];
    id sut = OCMPartialMock(context);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];
    [sut cancel];

    OCMVerify([mockVC presentViewController:[OCMArg isKindOfClass:[SFSafariViewController class]]
                                   animated:YES
                                 completion:[OCMArg any]]);
    OCMVerify([sut unsubscribeFromNotifications]);
    OCMVerify([sut dismissPresentedViewController]);
}

/**
 After starting a SafariViewController redirect flow,
 when the RedirectContext is dealloc'd, its dismiss method should be called.
 */
- (void)testSafariViewControllerRedirectFlow_dealloc {
    id mockVC = OCMClassMock([UIViewController class]);
    STPSource *source = [STPFixtures iDEALSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
        XCTFail(@"completion called");
    }];
    id sut = OCMPartialMock(context);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];
    sut = nil;

    OCMVerify([mockVC presentViewController:[OCMArg isKindOfClass:[SFSafariViewController class]]
                                   animated:YES
                                 completion:[OCMArg any]]);
    OCMVerify([sut unsubscribeFromNotifications]);
    OCMVerify([sut dismissPresentedViewController]);
}

/**
 After starting a SafariViewController redirect flow,
 if no action is taken, nothing should be called.
 */
- (void)testSafariViewControllerRedirectFlow_noAction {
    id mockVC = OCMClassMock([UIViewController class]);
    STPSource *source = [STPFixtures iDEALSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
        XCTFail(@"completion called");
    }];
    id sut = OCMPartialMock(context);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    OCMVerify([mockVC presentViewController:[OCMArg isKindOfClass:[SFSafariViewController class]]
                                   animated:YES
                                 completion:[OCMArg any]]);
    OCMReject([sut unsubscribeFromNotifications]);
    OCMReject([sut dismissPresentedViewController]);
}

/**
 After starting a Safari app redirect flow,
 when a WillEnterForeground notification is posted, RedirectContext's completion 
 block and dismiss method should be called.
 */
- (void)testSafariAppRedirectFlow_foregroundNotification {
    STPSource *source = [STPFixtures iDEALSource];
    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
        XCTAssertEqualObjects(sourceID, source.stripeID);
        XCTAssertEqualObjects(clientSecret, source.clientSecret);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    id sut = OCMPartialMock(context);

    [sut startSafariAppRedirectFlow];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];

    OCMVerify([sut unsubscribeFromNotifications]);
    OCMVerify([sut dismissPresentedViewController]);
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 After starting a Safari app redirect flow,
 if no notification is posted, nothing should be called.
 */
- (void)testSafariAppRedirectFlow_noNotification {
    STPSource *source = [STPFixtures iDEALSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
        XCTFail(@"completion called");
    }];
    id sut = OCMPartialMock(context);

    [sut startSafariAppRedirectFlow];

    OCMReject([sut unsubscribeFromNotifications]);
    OCMReject([sut dismissPresentedViewController]);
}

/**
 If a source type that supports native redirect is used and it contains a native
 url, an app to app redirect should attempt to be initiated.
 */
- (void)testNativeRedirectSupportingSourceFlow_validNativeURL {
    STPSource *source = [STPFixtures alipaySourceWithNativeUrl];
    NSURL *sourceURL = [NSURL URLWithString:source.details[@"native_url"]];

    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source
                                                                  completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
        XCTFail(@"completion called");
    }];
    id sut = OCMPartialMock(context);

    id applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);
    OCMStub([applicationMock openURL:[OCMArg any]
                             options:[OCMArg any]
                   completionHandler:([OCMArg invokeBlockWithArgs:@YES, nil])]);

    id mockVC = OCMClassMock([UIViewController class]);
    [context startRedirectFlowFromViewController:mockVC];

    OCMReject([sut startSafariViewControllerRedirectFlowFromViewController:[OCMArg any]]);
    OCMReject([sut startSafariAppRedirectFlow]);
    OCMVerify([applicationMock openURL:[OCMArg isEqual:sourceURL]
                               options:[OCMArg isEqual:@{}]
                     completionHandler:[OCMArg isNotNil]]);
}

/**
 If a source type that supports native redirect is used and it does not
 contain a native url, standard web view redirect should be attempted
 */
- (void)testNativeRedirectSupportingSourceFlow_invalidNativeURL {
    STPSource *source = [STPFixtures alipaySource];

    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source
                                                                  completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
                                                                      XCTFail(@"completion called");
                                                                  }];
    id sut = OCMPartialMock(context);

    id applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);

    id mockVC = OCMClassMock([UIViewController class]);
    [context startRedirectFlowFromViewController:mockVC];

    OCMVerify([sut startSafariViewControllerRedirectFlowFromViewController:[OCMArg isEqual:mockVC]]);
    OCMReject([applicationMock openURL:[OCMArg any]
                               options:[OCMArg any]
                     completionHandler:[OCMArg any]]);
    OCMVerify([mockVC presentViewController:[OCMArg isKindOfClass:[SFSafariViewController class]]
                                   animated:YES
                                 completion:[OCMArg isNil]]);
}

#pragma mark - Helpers

- (STPRedirectContextCompletionBlock)failingCompletionBlock {
    return ^(NSString *sourceID, NSString *clientSecret, NSError *error) {
        XCTFail("Should not have called completion: sourceID=%@, clientSecret=%@, error=%@", sourceID, clientSecret, error);
    };
}

@end
