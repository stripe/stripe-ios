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
#import "STPRedirectContext+Private.h"
#import "STPTestUtils.h"
#import "STPURLCallbackHandler.h"

@interface STPRedirectContext (Testing)
- (void)unsubscribeFromNotifications;
- (void)dismissPresentedViewController;
- (void)handleRedirectCompletionWithError:(nullable NSError *)error
              shouldDismissViewController:(BOOL)shouldDismissViewController;
@end

@interface STPRedirectContextTest : XCTestCase
@property (nonatomic, weak) STPRedirectContext *weak_sut;
@end

/*
 NOTE:

 If you are adding a test make sure your context unsubscribes from notifications
 before your test ends. Otherwise notifications fired from other tests can cause
 a reaction in an earlier, completed test and cause strange failures.

 Possible ways to do this:
 1. Your sut should already be calling unsubscribe, verified by OCMVerify
     - you're good
 2. Your sut doesn't call unsubscribe as part of the test but it's not explicitly
     disallowed - call [sut unsubscribeFromNotifications] at the end of your test
 3. Your sut doesn't call unsubscribe and you explicitly OCMReject it firing
     - call [self unsubscribeContext:context] at the end of your test (use
     the original context object here and _NOT_ the sut or it will not work).
 */
@implementation STPRedirectContextTest


/**
 Use this to unsubscribe a context from notifications without calling
 `sut.unsubscrbeFromNotifications` if you have OCMReject'd that method and thus
 can't call it.

 Note: You MUST pass in the actual context object here and not the mock or the
 unsubscibe will silently fail.
 */
- (void)unsubscribeContext:(STPRedirectContext *)context {
    [[NSNotificationCenter defaultCenter] removeObserver:context
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[STPURLCallbackHandler shared] unregisterListener:(id<STPURLCallbackListener>)context];
}

- (void)testInitWithNonRedirectSourceReturnsNil {
    STPSource *source = [STPFixtures cardSource];
    STPRedirectContext *sut = [[STPRedirectContext alloc] initWithSource:source completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
        XCTFail(@"completion was called");
    }];
    XCTAssertNil(sut);
}

- (void)testInitWithConsumedSourceReturnsNil {
    NSMutableDictionary *json = [[STPTestUtils jsonNamed:STPTestJSONSourceCard] mutableCopy];
    json[@"status"] = @"consumed";
    STPSource *source = [STPSource decodedObjectFromAPIResponse:json];
    STPRedirectContext *sut = [[STPRedirectContext alloc] initWithSource:source completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
        XCTFail(@"completion was called");
    }];
    XCTAssertNil(sut);
}

- (void)testInitWithSource {
    STPSource *source = [STPFixtures iDEALSource];
    __block BOOL completionCalled = NO;
    NSError *fakeError = [NSError new];

    STPRedirectContext *sut = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString * _Nonnull sourceID, NSString * _Nullable clientSecret, NSError * _Nullable error) {
        XCTAssertEqualObjects(source.stripeID, sourceID);
        XCTAssertEqualObjects(source.clientSecret, clientSecret);
        XCTAssertEqual(error, fakeError, @"Should be the same NSError object passed to completion() below");
        completionCalled = YES;
    }];

    // Make sure the initWithSource: method pulled out the right values from the Source
    XCTAssertNil(sut.nativeRedirectURL);
    XCTAssertEqualObjects(sut.redirectURL, source.redirect.url);
    XCTAssertEqualObjects(sut.returnURL, source.redirect.returnURL);

    // and make sure the completion calls the completion block above
    sut.completion(fakeError);
    XCTAssertTrue(completionCalled);
}

- (void)testInitWithSourceWithNativeURL {
    STPSource *source = [STPFixtures alipaySourceWithNativeURL];
    __block BOOL completionCalled = NO;
    NSURL *nativeURL = [NSURL URLWithString:source.details[@"native_url"]];
    NSError *fakeError = [NSError new];

    STPRedirectContext *sut = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString * _Nonnull sourceID, NSString * _Nullable clientSecret, NSError * _Nullable error) {
        XCTAssertEqualObjects(source.stripeID, sourceID);
        XCTAssertEqualObjects(source.clientSecret, clientSecret);
        XCTAssertEqual(error, fakeError, @"Should be the same NSError object passed to completion() below");
        completionCalled = YES;
    }];

    // Make sure the initWithSource: method pulled out the right values from the Source
    XCTAssertEqualObjects(sut.nativeRedirectURL, nativeURL);
    XCTAssertEqualObjects(sut.redirectURL, source.redirect.url);
    XCTAssertEqualObjects(sut.returnURL, source.redirect.returnURL);

    // and make sure the completion calls the completion block above
    sut.completion(fakeError);
    XCTAssertTrue(completionCalled);
}

- (void)testInitWithPaymentIntent {
    STPPaymentIntent *paymentIntent = [STPFixtures paymentIntent];
    __block BOOL completionCalled = NO;
    NSError *fakeError = [NSError new];

    STPRedirectContext *sut = [[STPRedirectContext alloc] initWithPaymentIntent:paymentIntent completion:^(NSString * _Nonnull clientSecret, NSError * _Nullable error) {
        XCTAssertEqualObjects(paymentIntent.clientSecret, clientSecret);
        XCTAssertEqual(error, fakeError, @"Should be the same NSError object passed to completion() below");
        completionCalled = YES;
    }];

    // Make sure the initWithPaymentIntent: method pulled out the right values from the PaymentIntent
    XCTAssertNil(sut.nativeRedirectURL);
    XCTAssertEqualObjects(sut.redirectURL.absoluteString,
                          @"https://hooks.stripe.com/redirect/authenticate/src_1Cl1AeIl4IdHmuTb1L7x083A?client_secret=src_client_secret_DBNwUe9qHteqJ8qQBwNWiigk");

    // `nextSourceAction` & `authorizeWithURL` should just be aliases for `nextAction` & `redirectToURL`, already tested in `STPPaymentIntentTest`
    XCTAssertNotNil(paymentIntent.nextAction.redirectToURL.returnURL);
    XCTAssertEqualObjects(sut.returnURL, paymentIntent.nextAction.redirectToURL.returnURL);

    // and make sure the completion calls the completion block above
    XCTAssertNotNil(sut);
    if (sut.completion) {
        sut.completion(fakeError);
    }
    XCTAssertTrue(completionCalled);
}

- (void)testInitWithPaymentIntentFailures {
    // Note next_action has been renamed to next_source_action in the API, but both still get sent down in the 2015-10-12 API
    NSMutableDictionary *json = [[STPTestUtils jsonNamed:STPTestJSONPaymentIntent] mutableCopy];
    json[@"next_action"] = [json[@"next_action"] mutableCopy];
    json[@"next_action"][@"redirect_to_url"] = [json[@"next_action"][@"redirect_to_url"] mutableCopy];

    void (^unusedCompletion)(NSString *, NSError *) = ^(__unused NSString * _Nonnull clientSecret, __unused NSError * _Nullable error) {
        XCTFail(@"should not be constructed, definitely not completed");
    };

    STPRedirectContext *(^create)(void) = ^{
        STPPaymentIntent *paymentIntent = [STPPaymentIntent decodedObjectFromAPIResponse:json];
        return [[STPRedirectContext alloc] initWithPaymentIntent:paymentIntent
                                                      completion:unusedCompletion];
    };

    XCTAssertNotNil(create(), @"before mutation of json, creation should succeed");

    json[@"status"] = @"processing";
    XCTAssertNil(create(), @"not created with wrong status");
    json[@"status"] = @"requires_action";

    json[@"next_action"][@"type"] = @"not_redirect_to_url";
    XCTAssertNil(create(), @"not created with wrong next_action.type");
    json[@"next_action"][@"type"] = @"redirect_to_url";

    NSString *correctURL = json[@"next_action"][@"redirect_to_url"][@"url"];
    json[@"next_action"][@"redirect_to_url"][@"url"] = @"not a valid URL";
    XCTAssertNil(create(), @"not created with an invalid URL in next_action.redirect_to_url.url");
    json[@"next_action"][@"redirect_to_url"][@"url"] = correctURL;

    NSString *correctReturnURL = json[@"next_action"][@"redirect_to_url"][@"return_url"];
    json[@"next_action"][@"redirect_to_url"][@"return_url"] = @"not a url";
    XCTAssertNil(create(), @"not created with invalid returnUrl");
    json[@"next_action"][@"redirect_to_url"][@"return_url"] = correctReturnURL;

    XCTAssertNotNil(create(), @"works again when everything is back to normal");
}

/**
 After starting a SafariViewController redirect flow,
 when a DidBecomeActive notification is posted, RedirectContext's completion
 block and dismiss method should _NOT_ be called.
 */
- (void)testSafariViewControllerRedirectFlow_activeNotification {
    id mockVC = OCMClassMock([UIViewController class]);
    STPSource *source = [STPFixtures iDEALSource];

    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
         XCTFail(@"completion called");
    }];
    id sut = OCMPartialMock(context);

    OCMReject([sut unsubscribeFromNotifications]);
    OCMReject([sut dismissPresentedViewController]);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

    BOOL(^checker)(id) = ^BOOL(id vc) {
        if ([vc isKindOfClass:[SFSafariViewController class]]) {
            return YES;
        }
        return NO;
    };

    OCMVerify([mockVC presentViewController:[OCMArg checkWithBlock:checker]
                                   animated:YES
                                 completion:[OCMArg any]]);
    [self unsubscribeContext:context];
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
    XCTAssertEqualObjects(source.redirect.returnURL, context.returnURL);
    id sut = OCMPartialMock(context);

    OCMStub([sut handleRedirectCompletionWithError:[OCMArg any] shouldDismissViewController:YES]).andForwardToRealObject().andDo(^(__unused NSInvocation *invocation) {
        [context safariViewControllerDidCompleteDismissal:[[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://www.stripe.com"]]];
    });

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
 RedirectContext's completion block and dismiss method should not be called.
 */
- (void)testSafariViewControllerRedirectFlow_callbackHandlerCalledInvalidURL {
    id mockVC = OCMClassMock([UIViewController class]);
    STPSource *source = [STPFixtures iDEALSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
        XCTFail(@"completion called");
    }];
    id sut = OCMPartialMock(context);

    OCMReject([sut unsubscribeFromNotifications]);
    OCMReject([sut dismissPresentedViewController]);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    BOOL(^checker)(id) = ^BOOL(id vc) {
        if ([vc isKindOfClass:[SFSafariViewController class]]) {
            NSURL *url = [NSURL URLWithString:@"my-app://some_path"];
            XCTAssertNotEqualObjects(url, context.returnURL);
            [[STPURLCallbackHandler shared] handleURLCallback:url];
            return YES;
        }
        return NO;
    };
    OCMVerify([mockVC presentViewController:[OCMArg checkWithBlock:checker]
                                   animated:YES
                                 completion:[OCMArg any]]);


    [self unsubscribeContext:context];
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
        // because we are manually invoking the dismissal, we report this as a cancelation
        XCTAssertEqual(error.domain, StripeDomain);
        XCTAssertEqual(error.code, STPCancellationError);
        [exp fulfill];
    }];
    id sut = OCMPartialMock(context);

    // dismiss should not be called – SafariVC dismisses itself when Done is tapped
    OCMReject([sut dismissPresentedViewController]);

    OCMStub([sut handleRedirectCompletionWithError:[OCMArg any] shouldDismissViewController:NO]).andForwardToRealObject().andDo(^(__unused NSInvocation *invocation) {
        [context safariViewControllerDidCompleteDismissal:[[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://www.stripe.com"]]];
    });

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

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 After starting a SafariViewController redirect flow,
 when SafariViewController fails to load the initial page (on iOS 11+ & without redirects),
 RedirectContext's completion block and dismiss method should be called.
 */
- (void)testSafariViewControllerRedirectFlow_failedInitialLoad_iOS11Plus {

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

    OCMStub([sut handleRedirectCompletionWithError:[OCMArg any] shouldDismissViewController:YES]).andForwardToRealObject().andDo(^(__unused NSInvocation *invocation) {
        [context safariViewControllerDidCompleteDismissal:[[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://www.stripe.com"]]];
    });

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
 when SafariViewController fails to load the initial page (on iOS 11+ after redirecting to non-Stripe page),
 RedirectContext's completion block should not be called (SFVC keeps loading)
 */

- (void)testSafariViewControllerRedirectFlow_failedInitialLoadAfterRedirect_iOS11Plus {
    id mockVC = OCMClassMock([UIViewController class]);
    STPSource *source = [STPFixtures iDEALSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
        XCTFail(@"completion called");
    }];
    id sut = OCMPartialMock(context);

    OCMReject([sut unsubscribeFromNotifications]);
    OCMReject([sut dismissPresentedViewController]);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    BOOL(^checker)(id) = ^BOOL(id vc) {
        if ([vc isKindOfClass:[SFSafariViewController class]]) {
            SFSafariViewController *sfvc = (SFSafariViewController *)vc;
            // before initial load is done, SFVC was redirected to a non-stripe.com domain
            [sfvc.delegate safariViewController:sfvc
                    initialLoadDidRedirectToURL:[NSURL URLWithString:@"https://girogate.de"]];
            // Tell the delegate that the initial load failed.
            // on iOS 11, with the redirect, this is a no-op
            [sfvc.delegate safariViewController:sfvc didCompleteInitialLoad:NO];
            return YES;
        }
        return NO;
    };
    OCMVerify([mockVC presentViewController:[OCMArg checkWithBlock:checker]
                                   animated:YES
                                 completion:[OCMArg any]]);

    [self unsubscribeContext:context];
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
 if no action is taken, nothing should be called.
 */
- (void)testSafariViewControllerRedirectFlow_noAction {
    id mockVC = OCMClassMock([UIViewController class]);
    STPSource *source = [STPFixtures iDEALSource];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
        XCTFail(@"completion called");
    }];
    id sut = OCMPartialMock(context);

    OCMReject([sut unsubscribeFromNotifications]);
    OCMReject([sut dismissPresentedViewController]);

    [sut startSafariViewControllerRedirectFlowFromViewController:mockVC];

    OCMVerify([mockVC presentViewController:[OCMArg isKindOfClass:[SFSafariViewController class]]
                                   animated:YES
                                 completion:[OCMArg any]]);

    [self unsubscribeContext:context];
}

/**
 After starting a Safari app redirect flow,
 when a DidBecomeActive notification is posted, RedirectContext's completion
 block and dismiss method should be called.
 */
- (void)testSafariAppRedirectFlow_activeNotification {
    __block id sut;

    STPSource *source = [STPFixtures iDEALSource];
    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
        XCTAssertEqualObjects(sourceID, source.stripeID);
        XCTAssertEqualObjects(clientSecret, source.clientSecret);
        XCTAssertNil(error);

        OCMVerify([sut unsubscribeFromNotifications]);

        [exp fulfill];
    }];
    sut = OCMPartialMock(context);

    [sut startSafariAppRedirectFlow];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

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

    OCMReject([sut unsubscribeFromNotifications]);
    OCMReject([sut dismissPresentedViewController]);

    [sut startSafariAppRedirectFlow];

    [self unsubscribeContext:context];
}

/**
 If a source type that supports native redirect is used and it contains a native
 url, an app to app redirect should attempt to be initiated.
 */
- (void)testNativeRedirectSupportingSourceFlow_validNativeURL {
    STPSource *source = [STPFixtures alipaySourceWithNativeURL];
    NSURL *sourceURL = [NSURL URLWithString:source.details[@"native_url"]];

    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source
                                                                  completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
        XCTFail(@"completion called");
    }];

    XCTAssertNotNil(context.nativeRedirectURL);
    XCTAssertEqualObjects(context.nativeRedirectURL, sourceURL);

    id sut = OCMPartialMock(context);

    id applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);
    OCMStub([applicationMock openURL:[OCMArg any]
                             options:[OCMArg any]
                   completionHandler:([OCMArg invokeBlockWithArgs:@YES, nil])]);

    OCMReject([sut startSafariViewControllerRedirectFlowFromViewController:[OCMArg any]]);
    OCMReject([sut startSafariAppRedirectFlow]);

    id mockVC = OCMClassMock([UIViewController class]);
    [sut startRedirectFlowFromViewController:mockVC];

    OCMVerify([applicationMock openURL:[OCMArg isEqual:sourceURL]
                               options:[OCMArg isEqual:@{}]
                     completionHandler:[OCMArg isNotNil]]);

    [sut unsubscribeFromNotifications];
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
    XCTAssertNil(context.nativeRedirectURL);

    id sut = OCMPartialMock(context);

    id applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);

    OCMReject([applicationMock openURL:[OCMArg any]
                               options:[OCMArg any]
                     completionHandler:[OCMArg any]]);

    id mockVC = OCMClassMock([UIViewController class]);
    [sut startRedirectFlowFromViewController:mockVC];

    OCMVerify([sut startSafariViewControllerRedirectFlowFromViewController:[OCMArg isEqual:mockVC]]);

    OCMVerify([mockVC presentViewController:[OCMArg isKindOfClass:[SFSafariViewController class]]
                                   animated:YES
                                 completion:[OCMArg isNil]]);

    [sut unsubscribeFromNotifications];
}

#pragma mark - WeChat Pay

/**
 If a WeChat source type is used, we should attempt an app redirect.
 */
- (void)testWeChatPaySource_appRedirectSucceeds {
    STPSource *source = [STPFixtures weChatPaySource];
    NSURL *sourceURL = [NSURL URLWithString:source.weChatPayDetails.weChatAppURL];
    
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source
                                                                  completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
                                                                      XCTFail(@"completion called");
                                                                  }];
    
    XCTAssertNotNil(context.nativeRedirectURL);
    XCTAssertEqualObjects(context.nativeRedirectURL, sourceURL);
    XCTAssertNil(context.redirectURL);
    XCTAssertNotNil(context.returnURL);
    
    id sut = OCMPartialMock(context);
    
    id applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);
    OCMStub([applicationMock openURL:[OCMArg any]
                             options:[OCMArg any]
                   completionHandler:([OCMArg invokeBlockWithArgs:@YES, nil])]);
    
    OCMReject([sut startSafariViewControllerRedirectFlowFromViewController:[OCMArg any]]);
    OCMReject([sut startSafariAppRedirectFlow]);
    
    id mockVC = OCMClassMock([UIViewController class]);
    [sut startRedirectFlowFromViewController:mockVC];
    
    OCMVerify([applicationMock openURL:[OCMArg isEqual:sourceURL]
                               options:[OCMArg isEqual:@{}]
                     completionHandler:[OCMArg isNotNil]]);
    
    [sut unsubscribeFromNotifications];
}

/**
 If a WeChat source type is used, we should attempt an app redirect.
 If app redirect fails, expect an error.
 */
- (void)testWeChatPaySource_appRedirectFails {
    STPSource *source = [STPFixtures weChatPaySource];
    NSURL *sourceURL = [NSURL URLWithString:source.weChatPayDetails.weChatAppURL];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block called"];
    STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source
                                                                  completion:^(__unused NSString *sourceID, __unused NSString *clientSecret, __unused NSError *error) {
                                                                      XCTAssertNotNil(error);
                                                                      XCTAssertEqual(error.domain, STPRedirectContextErrorDomain);
                                                                      XCTAssertEqual(error.code, STPRedirectContextAppRedirectError);
                                                                      [expectation fulfill];
                                                                  }];
    
    XCTAssertNotNil(context.nativeRedirectURL);
    XCTAssertEqualObjects(context.nativeRedirectURL, sourceURL);
    XCTAssertNil(context.redirectURL);
    XCTAssertNotNil(context.returnURL);
    
    id sut = OCMPartialMock(context);
    
    id applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);
    OCMStub([applicationMock openURL:[OCMArg any]
                             options:[OCMArg any]
                   completionHandler:([OCMArg invokeBlockWithArgs:@NO, nil])]);
    
    OCMReject([sut startSafariViewControllerRedirectFlowFromViewController:[OCMArg any]]);
    OCMReject([sut startSafariAppRedirectFlow]);
    
    id mockVC = OCMClassMock([UIViewController class]);
    [sut startRedirectFlowFromViewController:mockVC];
    
    OCMVerify([applicationMock openURL:[OCMArg isEqual:sourceURL]
                               options:[OCMArg isEqual:@{}]
                     completionHandler:[OCMArg isNotNil]]);
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}


@end
