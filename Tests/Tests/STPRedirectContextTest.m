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

@interface STPSource ()
@property (nonatomic, readwrite) STPSourceFlow flow;
@property (nonatomic, readwrite) STPSourceStatus status;
@property (nonatomic, nullable, readwrite) NSDictionary *details;
@end

@interface STPSourceRedirect ()
@property (nonatomic, nullable) NSURL *returnURL;
@property (nonatomic, nullable) NSURL *url;
@end

@interface STPRedirectContext ()
- (void)unsubscribeFromUrlAndForegroundNotifications;
- (void)dismissPresentedViewController;
@end

@interface STPRedirectContextTest : XCTestCase

@end

@implementation STPRedirectContextTest

#pragma mark - Init

- (void)testInitWithSourceCompletion_nonRedirectSource {
    // Should return `nil` for non-redirect source
    STPSource *source = [STPFixtures cardSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
    XCTAssertNil(context);
}

- (void)testInitWithSourceCompletion_nonRedirectFlow {
    // Should return `nil` for source with non-redirect flow
    NSArray *sourceFlows = @[@(STPSourceFlowNone),
                             @(STPSourceFlowCodeVerification),
                             @(STPSourceFlowReceiver),
                             @(STPSourceFlowUnknown)];

    for (NSNumber *flowNumber in sourceFlows) {
        STPSource *source = [STPFixtures iDEALSource];
        source.flow = flowNumber.integerValue;
        STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
        XCTAssertNil(context);
    }
}

- (void)testInitWithSourceCompletion_statusNotPending {
    // Should return `nil` for source with non-pending status
    NSArray *sourceStatuses = @[@(STPSourceStatusChargeable),
                                @(STPSourceStatusConsumed),
                                @(STPSourceStatusCanceled),
                                @(STPSourceStatusFailed),
                                @(STPSourceStatusUnknown)];

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

- (void)testInitWithSourceCompletion_missingRedirectURL {
    // Should return `nil` for source with missing redirect url
    STPSource *source = [STPFixtures iDEALSource];
    source.redirect.url = nil;
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
    XCTAssertNil(context);
}

- (void)testInitWithSourceCompletion_validWebRedirectSource {
    // Should return object for valid redirect source
    STPSource *source = [STPFixtures iDEALSource];
    XCTAssert(source.redirect.url);  // Required field for redirect
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
    XCTAssert(context);
}

- (void)testInitWithSourceCompletion_validNativeRedirectSource {
    // Should return object for valid native redirect source
    STPSource *source = [STPFixtures alipaySourceWithNativeUrl];
    source.redirect.url = nil;  // Force native url only
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
    XCTAssert(context);
}

#pragma mark - startSafariViewControllerRedirectFlowFromViewController

/**
 After starting a SFSafariViewController redirect flow,
 when the STPURLCallbackHandler is called with a valid URL,
 should execute STPRedirectContext completion block and dismiss SFSafariViewController.
 */
- (void)testSafariViewControllerRedirectFlow_callbackHandlerCalledValidURL {
    if ([SFSafariViewController class] == nil) {
        // Method not supported by iOS version
        return;
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"completion"];

    STPSource *source = [STPFixtures iDEALSource];
    id mockVC = OCMClassMock([UIViewController class]);
    BOOL (^checker)(id) = ^BOOL (id viewController) {
        if ([viewController isKindOfClass:[SFSafariViewController class]]) {
            [self notifyURLCallbackHandlerWithSource:source];
            return YES;
        }
        return NO;
    };
    OCMStub([mockVC presentViewController:[OCMArg checkWithBlock:checker] animated:YES completion:[OCMArg any]]);
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
        XCTAssertEqualObjects(sourceID, source.stripeID);
        XCTAssertEqualObjects(clientSecret, source.clientSecret);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    id sut = OCMPartialMock(context);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    OCMVerify([mockVC presentViewController:[OCMArg any] animated:[OCMArg any] completion:[OCMArg any]]);
    OCMVerify([sut unsubscribeFromUrlAndForegroundNotifications]);
    OCMVerify([sut dismissPresentedViewController]);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/**
 After starting a SFSafariViewController redirect flow,
 when the STPURLCallbackHandler is called with an invalid URL,
 should not execute STPRedirectContext completion block nor dismiss SFSafariViewController.
 */
- (void)testSafariViewControllerRedirectFlow_callbackHandlerCalledInvalidURL {
    if ([SFSafariViewController class] == nil) {
        // Method not supported by iOS version
        return;
    }

    STPSource *source = [STPFixtures iDEALSource];
    id mockVC = OCMClassMock([UIViewController class]);
    BOOL(^checker)(id) = ^BOOL(id viewController) {
        if ([viewController isKindOfClass:[SFSafariViewController class]]) {
            [[STPURLCallbackHandler shared] handleURLCallback:[NSURL URLWithString:@"my-app://some_path"]];
            return YES;
        }
        return NO;
    };
    OCMStub([mockVC presentViewController:[OCMArg checkWithBlock:checker] animated:[OCMArg any] completion:[OCMArg any]]);
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
    id sut = OCMPartialMock(context);
    OCMReject([sut unsubscribeFromUrlAndForegroundNotifications]);
    OCMReject([sut dismissPresentedViewController]);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    OCMVerify([mockVC presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);
}

/**
 After starting a SFSafariViewController redirect flow,
 when SFSafariViewController calls `safariViewControllerDidFinish` because the user tapped "Done",
 should execute STPRedirectContext completion block.
 */
- (void)testSafariViewControllerRedirectFlow_didFinish {
    if ([SFSafariViewController class] == nil) {
        // Method not supported by iOS version
        return;
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"completion"];

    STPSource *source = [STPFixtures iDEALSource];
    id mockVC = OCMClassMock([UIViewController class]);
    BOOL(^checker)(id) = ^BOOL(id viewController) {
        if ([viewController isKindOfClass:[SFSafariViewController class]]) {
            SFSafariViewController *safariViewController = (SFSafariViewController *)viewController;
            [safariViewController.delegate safariViewControllerDidFinish:safariViewController];
            return YES;
        }
        return NO;
    };
    OCMStub([mockVC presentViewController:[OCMArg checkWithBlock:checker] animated:[OCMArg any] completion:[OCMArg any]]);
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
        XCTAssertEqualObjects(sourceID, source.stripeID);
        XCTAssertEqualObjects(clientSecret, source.clientSecret);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    id sut = OCMPartialMock(context);
    OCMReject([sut dismissPresentedViewController]);  // The SFSafariViewController dismisses itself when Done is tapped so `dismissPresentedViewController` should not be called

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    OCMVerify([mockVC presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);
    OCMVerify([sut unsubscribeFromUrlAndForegroundNotifications]);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/**
 After starting a SFSafariViewController redirect flow,
 when SFSafariViewController calls `didCompleteInitialLoad:NO`,
 should execute STPRedirectContext completion block with error object and dismiss SFSafariViewController.
 */
- (void)testSafariViewControllerRedirectFlow_failedToLoad {
    if ([SFSafariViewController class] == nil) {
        // Method not supported by iOS version
        return;
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"completion"];

    STPSource *source = [STPFixtures iDEALSource];
    id mockVC = OCMClassMock([UIViewController class]);
    BOOL(^checker)(id) = ^BOOL(id viewController) {
        if ([viewController isKindOfClass:[SFSafariViewController class]]) {
            SFSafariViewController *safariViewController = (SFSafariViewController *)viewController;
            [safariViewController.delegate safariViewController:safariViewController didCompleteInitialLoad:NO];
            return YES;
        }
        return NO;
    };
    OCMStub([mockVC presentViewController:[OCMArg checkWithBlock:checker] animated:[OCMArg any] completion:[OCMArg any]]);
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
        XCTAssertEqualObjects(sourceID, source.stripeID);
        XCTAssertEqualObjects(clientSecret, source.clientSecret);
        XCTAssertEqualObjects(error, [NSError stp_genericConnectionError]);
        [expectation fulfill];
    }];
    id sut = OCMPartialMock(context);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    OCMVerify([mockVC presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);
    OCMVerify([sut unsubscribeFromUrlAndForegroundNotifications]);
    OCMVerify([sut dismissPresentedViewController]);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/**
 After starting a SFSafariViewController redirect flow,
 when STPRedirectContext `cancel` is called,
 should dismiss SFSafariViewController.
 */
- (void)testSafariViewControllerRedirectFlow_cancel {
    if ([SFSafariViewController class] == nil) {
        // Method not supported by iOS version
        return;
    }

    STPSource *source = [STPFixtures iDEALSource];
    id mockVC = OCMClassMock([UIViewController class]);
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
    id sut = OCMPartialMock(context);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];
    [sut cancel];

    OCMVerify([mockVC presentViewController:[OCMArg isKindOfClass:[SFSafariViewController class]] animated:YES completion:[OCMArg any]]);
    OCMVerify([sut unsubscribeFromUrlAndForegroundNotifications]);
    OCMVerify([sut dismissPresentedViewController]);
}

/**
 After starting a SFSafariViewControledirler redirect flow,
 when the STPRedirectContext is deallocated,
 should stop listening to callbacks (and dismiss SFSafariViewController but not tested due to complexity).
 */
- (void)testSafariViewControllerRedirectFlow_dealloc {
    if ([SFSafariViewController class] == nil) {
        // Method not supported by iOS version
        return;
    }

    STPSource *source = [STPFixtures iDEALSource];
    UIViewController *viewController = [[UIViewController alloc] init];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];

    [context startSafariViewControllerRedirectFlowFromViewController:viewController];
    context = nil;

    [self notifyURLCallbackHandlerWithSource:source];  // Should do nothing!
}

/**
 After starting a SFSafariViewController redirect flow,
 when no action is taken,
 nothing should be called.
 */
- (void)testSafariViewControllerRedirectFlow_noAction {
    if ([SFSafariViewController class] == nil) {
        // Method not supported by iOS version
        return;
    }

    STPSource *source = [STPFixtures iDEALSource];
    id mockVC = OCMClassMock([UIViewController class]);
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
    id sut = OCMPartialMock(context);
    OCMReject([sut unsubscribeFromUrlAndForegroundNotifications]);
    OCMReject([sut dismissPresentedViewController]);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    OCMVerify([mockVC presentViewController:[OCMArg isKindOfClass:[SFSafariViewController class]] animated:[OCMArg any] completion:[OCMArg any]]);
}

#pragma mark - startSafariAppRedirectFlow

/**
 After starting a Safari app redirect flow,
 when `UIApplicationWillEnterForegroundNotification` is posted,
 should execute STPRedirectContext completion block with error object and dismiss just in case.
 */
- (void)testSafariAppRedirectFlow_foregroundNotification {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completion"];

    STPSource *source = [STPFixtures iDEALSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
        XCTAssertEqualObjects(sourceID, source.stripeID);
        XCTAssertEqualObjects(clientSecret, source.clientSecret);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    id sut = OCMPartialMock(context);

    [sut startSafariAppRedirectFlow];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];

    OCMVerify([sut unsubscribeFromUrlAndForegroundNotifications]);
    OCMVerify([sut dismissPresentedViewController]);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/**
 After starting a Safari app redirect flow,
 when no notification is posted,
 nothing should be called.
 */
- (void)testSafariAppRedirectFlow_noNotification {
    STPSource *source = [STPFixtures iDEALSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
    id sut = OCMPartialMock(context);
    OCMReject([sut unsubscribeFromUrlAndForegroundNotifications]);
    OCMReject([sut dismissPresentedViewController]);

    [sut startSafariAppRedirectFlow];
}

#pragma mark - startRedirectFlowFromViewController

/**
 If a source with `STPSourceType` that supports native redirects is used,
 and `source.details` contains a `native_url`,
 should attempt to initiate an app to app redirect.
 */
- (void)testNativeRedirectSupportingSourceFlow_validNativeURL {
    STPSource *source = [STPFixtures alipaySourceWithNativeUrl];

    NSURL *sourceURL = [NSURL URLWithString:source.details[@"native_url"]];

    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
    id sut = OCMPartialMock(context);
    OCMReject([sut startSafariViewControllerRedirectFlowFromViewController:[OCMArg any]]);
    OCMReject([sut startSafariAppRedirectFlow]);

    id applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        OCMStub([applicationMock openURL:[OCMArg any] options:[OCMArg any] completionHandler:([OCMArg invokeBlockWithArgs:@YES, nil])]);
    }
    else {
        OCMStub([applicationMock openURL:[OCMArg any]]).andReturn(YES);
    }

    id mockVC = OCMClassMock([UIViewController class]);
    [context startRedirectFlowFromViewController:mockVC];

    if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        OCMVerify([applicationMock openURL:[OCMArg isEqual:sourceURL] options:[OCMArg isEqual:@{}] completionHandler:[OCMArg isNotNil]]);
    }
    else {
        OCMVerify([applicationMock openURL:[OCMArg isEqual:sourceURL]]);
    }
}

/**
 If a source with `STPSourceType` that supports native redirects is used,
 and `source.details` does not contain a `native_url`,
 should start a SFSafariViewController redirect flow.
 */
- (void)testNativeRedirectSupportingSourceFlow_invalidNativeURL {
    STPSource *source = [STPFixtures alipaySource];

    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:[self failingCompletionBlock]];
    id sut = OCMPartialMock(context);

    id applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        OCMReject([applicationMock openURL:[OCMArg any] options:[OCMArg any] completionHandler:[OCMArg any]]);
    }
    else {
        OCMReject([applicationMock openURL:source.details[@"native_url"]]);
    }

    id mockVC = OCMClassMock([UIViewController class]);
    [context startRedirectFlowFromViewController:mockVC];

    if ([SFSafariViewController class] != nil) {
        OCMVerify([sut startSafariViewControllerRedirectFlowFromViewController:[OCMArg isEqual:mockVC]]);
        OCMVerify([mockVC presentViewController:[OCMArg isKindOfClass:[SFSafariViewController class]] animated:YES completion:[OCMArg isNil]]);
    }
    else {
        OCMVerify([sut startSafariAppRedirectFlow]);
        OCMVerify([applicationMock openURL:[OCMArg isEqual:source.redirect.url]]);
    }
}

#pragma mark - Helpers

- (STPRedirectContextCompletionBlock)failingCompletionBlock {
    return ^(NSString *sourceID, NSString *clientSecret, NSError *error) {
        XCTFail("Should not have called completion: sourceID=%@, clientSecret=%@, error=%@", sourceID, clientSecret, error);
    };
}

- (void)notifyURLCallbackHandlerWithSource:(STPSource *)source {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:source.redirect.returnURL resolvingAgainstBaseURL:NO];

    // Add typical `source` and `client_secret` query parameters
    [urlComponents setStp_queryItemsDictionary:@{@"source": source.stripeID, @"client_secret": source.clientSecret}];

    [[STPURLCallbackHandler shared] handleURLCallback:urlComponents.URL];
}

@end
