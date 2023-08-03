//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPRedirectContextTest.swift
//  Stripe
//
//  Created by Ben Guo on 4/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import SafariServices
import StripeCore

var sourceID: String?
var __unused: String = ""

extension STPRedirectContext {
    func unsubscribeFromNotifications() {
    }

    func dismissPresentedViewController() {
    }

    func handleRedirectCompletionWithError(
        _ error: Error?,
        shouldDismissViewController: Bool
    ) {
    }
}

var sut: STPRedirectContext?

class STPRedirectContextTest: XCTestCase {
    weak var weak_sut: STPRedirectContext?

    /// Use this to unsubscribe a context from notifications without calling
    /// `sut.unsubscrbeFromNotifications` if you have OCMReject'd that method and thus
    /// can't call it.
    /// Note: You MUST pass in the actual context object here and not the mock or the
    /// unsubscibe will silently fail.
    func unsubscribeContext(_ context: STPRedirectContext?) {
        if let context {
            NotificationCenter.default.removeObserver(
                context,
                name: UIApplicationDelegate.didBecomeActiveNotification,
                object: nil)
        }
        STPURLCallbackHandler.shared().unregisterListener(context as? STPURLCallbackListener?)
    }

    func testInitWithNonRedirectSourceReturnsNil() {
    }
}

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