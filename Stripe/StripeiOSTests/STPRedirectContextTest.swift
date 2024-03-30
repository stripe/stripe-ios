//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPRedirectContextTest.m
//  Stripe
//
//  Created by Ben Guo on 4/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import SafariServices
@_spi(STP) @testable import StripeCore
@testable import StripePayments

class MockUIViewController: UIViewController {
    var presentChecker: (UIViewController) -> Bool = { _ in return true }
    var presentCalled: Bool = false
    var dismiss: () -> Void = { }
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentCalled = true
        if !presentChecker(viewControllerToPresent) {
           XCTFail("checker failed")
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        dismiss()
    }
}

class MockUIApplication: UIApplicationProtocol {
    var openHandler: (URL, ((Bool) -> Void)?) -> Void = { _, completion in completion?(true) }
    var openCalled: Bool = false

    func _open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: ((Bool) -> Void)?) {
        openCalled = true
        openHandler(url, completion)
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
                name: UIApplication.didBecomeActiveNotification,
                object: nil)
            STPURLCallbackHandler.shared().unregisterListener(context)
        }
    }

    func testInitWithNonRedirectSourceReturnsNil() {
        let source = STPFixtures.cardSource()
        let sut = STPRedirectContext(source: source) { _, _, _ in
            XCTFail("completion was called")
        }
        XCTAssertNil(sut)
    }

    func testInitWithConsumedSourceReturnsNil() {
        var json = STPTestUtils.jsonNamed(STPTestJSONSourceCard)
        json?["status"] = "consumed"
        let source = STPSource.decodedObject(fromAPIResponse: json)!
        let sut = STPRedirectContext(source: source) { _, _, _ in
            XCTFail("completion was called")
        }
        XCTAssertNil(sut)
    }

    func testInitWithSource() {
        let source = STPFixtures.iDEALSource()
        var completionCalled = false
        let fakeError = NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)

        let sut = STPRedirectContext(source: source) { sourceID, clientSecret, error in
            XCTAssertEqual(source.stripeID, sourceID)
            XCTAssertEqual(source.clientSecret, clientSecret)
            XCTAssertEqual(error! as NSError, fakeError, "Should be the same NSError object passed to completion() below")
            completionCalled = true
        }

        // Make sure the initWithSource: method pulled out the right values from the Source
        XCTAssertNil(sut?.nativeRedirectURL)
        XCTAssertEqual(sut?.redirectURL, source.redirect?.url)
        XCTAssertEqual(sut?.returnURL, source.redirect?.returnURL)

        // and make sure the completion calls the completion block above
        sut?.completion(fakeError)
        XCTAssertTrue(completionCalled)
    }

    func testInitWithSourceWithNativeURL() {
        let source = STPFixtures.alipaySourceWithNativeURL()
        var completionCalled = false
        let nativeURL = URL(string: source.details?["native_url"] as? String ?? "")
        let fakeError = NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)

        let sut = STPRedirectContext(source: source) { sourceID, clientSecret, error in
            XCTAssertEqual(source.stripeID, sourceID)
            XCTAssertEqual(source.clientSecret, clientSecret)
            XCTAssertEqual(error! as NSError, fakeError, "Should be the same NSError object passed to completion() below")
            completionCalled = true
        }

        // Make sure the initWithSource: method pulled out the right values from the Source
        XCTAssertEqual(sut?.nativeRedirectURL, nativeURL)
        XCTAssertEqual(sut?.redirectURL, source.redirect?.url)
        XCTAssertEqual(sut?.returnURL, source.redirect?.returnURL)

        // and make sure the completion calls the completion block above
        sut?.completion(fakeError)
        XCTAssertTrue(completionCalled)
    }

    func testInitWithPaymentIntent() {
        let paymentIntent = STPFixtures.paymentIntent()
        var completionCalled = false
        let fakeError = NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)

        let sut = STPRedirectContext(paymentIntent: paymentIntent) { clientSecret, error in
            XCTAssertEqual(paymentIntent.clientSecret, clientSecret)
            XCTAssertEqual(error! as NSError, fakeError, "Should be the same NSError object passed to completion() below")
            completionCalled = true
        }

        // Make sure the initWithPaymentIntent: method pulled out the right values from the PaymentIntent
        XCTAssertNil(sut?.nativeRedirectURL)
        XCTAssertEqual(
            sut?.redirectURL?.absoluteString,
            "https://hooks.stripe.com/redirect/authenticate/src_1Cl1AeIl4IdHmuTb1L7x083A?client_secret=src_client_secret_DBNwUe9qHteqJ8qQBwNWiigk")

        // `nextSourceAction` & `authorizeWithURL` should just be aliases for `nextAction` & `redirectToURL`, already tested in `STPPaymentIntentTest`
        XCTAssertNotNil(paymentIntent.nextAction?.redirectToURL?.returnURL)
        XCTAssertEqual(sut?.returnURL, paymentIntent.nextAction?.redirectToURL?.returnURL)

        // and make sure the completion calls the completion block above
        XCTAssertNotNil(sut)
        sut?.completion(fakeError)
        XCTAssertTrue(completionCalled)
    }

    func testInitWithPaymentIntentFailures() {
        // Note next_action has been renamed to next_source_action in the API, but both still get sent down in the 2015-10-12 API
        let unusedCompletion: ((String?, Error?) -> Void) = { _, _ in
            XCTFail("should not be constructed, definitely not completed")
        }

        let create: (([AnyHashable: Any]) -> STPRedirectContext?) = { json in
            let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: json)!
            return STPRedirectContext(
                paymentIntent: paymentIntent,
                completion: unusedCompletion)
        }

        var json = STPTestUtils.jsonNamed(STPTestJSONPaymentIntent)!
        XCTAssertNotNil(create(json), "before mutation of json, creation should succeed")

        json["status"] = "processing"
        XCTAssertNil(create(json), "not created with wrong status")
        json["status"] = "requires_action"

        json[jsonDict: "next_action"]?["type"] = "not_redirect_to_url"
        XCTAssertNil(create(json), "not created with wrong next_action.type")
        json[jsonDict: "next_action"]?["type"] = "redirect_to_url"

        let correctURL = json[jsonDict: "next_action"]?[jsonDict: "redirect_to_url"]?["url"] as? String
        json[jsonDict: "next_action"]?[jsonDict: "redirect_to_url"]?["url"] = "not a valid URL"
        XCTAssertNil(create(json), "not created with an invalid URL in next_action.redirect_to_url.url")
        json[jsonDict: "next_action"]?[jsonDict: "redirect_to_url"]?["url"] = correctURL ?? ""

        let correctReturnURL = json[jsonDict: "next_action"]?[jsonDict: "redirect_to_url"]?["return_url"] as? String
        json[jsonDict: "next_action"]?[jsonDict: "redirect_to_url"]?["return_url"] = "not a url"
        XCTAssertNil(create(json), "not created with invalid returnUrl")
        json[jsonDict: "next_action"]?[jsonDict: "redirect_to_url"]?["return_url"] = correctReturnURL ?? ""

        XCTAssertNotNil(create(json), "works again when everything is back to normal")
    }

    /// After starting a SafariViewController redirect flow,
    /// when a DidBecomeActive notification is posted, RedirectContext's completion
    /// block and dismiss method should _NOT_ be called.
    func testSafariViewControllerRedirectFlow_activeNotification() {
        let mockVC = MockUIViewController()
        mockVC.presentChecker = { vc in
            if vc is SFSafariViewController {
                return true
            }
            return false
        }

        let source = STPFixtures.iDEALSource()

        let sut = STPRedirectContext(source: source) { _, _, _ in
            XCTFail("completion called")
        }!

        sut.startSafariViewControllerRedirectFlow(from: mockVC)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        unsubscribeContext(sut)
        XCTAssertFalse(sut._unsubscribeFromNotificationsCalled)
        XCTAssertFalse(sut._dismissPresentedViewControllerCalled)
        XCTAssertTrue(mockVC.presentCalled)
    }

    /// After starting a SafariViewController redirect flow,
    /// when the shared URLCallbackHandler is called with a valid URL,
    /// RedirectContext's completion block and dismiss method should be called.
    func testSafariViewControllerRedirectFlow_callbackHandlerCalledValidURL() {
        let mockVC = MockUIViewController()
        let source = STPFixtures.iDEALSource()
        mockVC.presentChecker = { vc in
            if vc is SFSafariViewController {
                let url = source.redirect!.returnURL
                let comps = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!
                comps.stp_queryItemsDictionary =
                [
                    "source": source.stripeID,
                    "client_secret": source.clientSecret!,
                ]
                STPURLCallbackHandler.shared().handleURLCallback(comps.url!)
                return true
            }
            return false
        }
        let exp = expectation(description: "completion")
        let sut = STPRedirectContext(source: source) { sourceID, clientSecret, error in
            XCTAssertEqual(sourceID, source.stripeID)
            XCTAssertEqual(clientSecret, source.clientSecret)
            XCTAssertNil(error)
            exp.fulfill()
        }!
        XCTAssertEqual(source.redirect?.returnURL, sut.returnURL)
        sut._handleRedirectCompletionWithErrorHook = { shouldDismissViewController in
            if shouldDismissViewController {
                sut.safariViewControllerDidCompleteDismissal(SFSafariViewController(url: URL(string: "https://www.stripe.com")!))
            }
        }

        sut.startSafariViewControllerRedirectFlow(from: mockVC)
        XCTAssertTrue(sut._unsubscribeFromNotificationsCalled)
        XCTAssertTrue(sut._dismissPresentedViewControllerCalled)
        XCTAssertTrue(mockVC.presentCalled)
        waitForExpectations(timeout: 2, handler: nil)
    }

    /// After starting a SafariViewController redirect flow,
    /// when the shared URLCallbackHandler is called with an invalid URL,
    /// RedirectContext's completion block and dismiss method should not be called.
    func testSafariViewControllerRedirectFlow_callbackHandlerCalledInvalidURL() {
        let mockVC = MockUIViewController()
        let source = STPFixtures.iDEALSource()
        let sut = STPRedirectContext(source: source) { _, _, _ in
            XCTFail("completion called")
        }!

        sut.startSafariViewControllerRedirectFlow(from: mockVC)

        mockVC.presentChecker = { vc in
            if vc is SFSafariViewController {
                let url = URL(string: "my-app://some_path")!
                XCTAssertNotEqual(url, sut.returnURL)
                STPURLCallbackHandler.shared().handleURLCallback(url)
                return true
            }
            return false
        }

        XCTAssertFalse(sut._unsubscribeFromNotificationsCalled)
        XCTAssertFalse(sut._dismissPresentedViewControllerCalled)
        XCTAssertTrue(mockVC.presentCalled)
        unsubscribeContext(sut)
    }

    /// After starting a SafariViewController redirect flow,
    /// when SafariViewController finishes, RedirectContext's completion block
    /// should be called.
    func testSafariViewControllerRedirectFlow_didFinish() {
        let mockVC = MockUIViewController()
        let source = STPFixtures.iDEALSource()

        let exp = expectation(description: "completion")
        let sut: STPRedirectContext = STPRedirectContext(source: source) { sourceID, clientSecret, error in
            XCTAssertEqual(sourceID, source.stripeID)
            XCTAssertEqual(clientSecret, source.clientSecret)
            // because we are manually invoking the dismissal, we report this as a cancelation
            let error = error! as NSError
            XCTAssertEqual(error.domain, STPError.stripeDomain)
            XCTAssertEqual(error.code, STPErrorCode.cancellationError.rawValue)
            exp.fulfill()
        }!

        sut._handleRedirectCompletionWithErrorHook = { shouldDismissViewController in
            if !shouldDismissViewController {
                sut.safariViewControllerDidCompleteDismissal(SFSafariViewController(url: URL(string: "https://www.stripe.com")!))
            }
        }
        mockVC.presentChecker = { vc in
            if vc is SFSafariViewController {
                let sfvc = vc as? SFSafariViewController
                if let sfvc {
                    sfvc.delegate?.safariViewControllerDidFinish?(sfvc)
                }
                return true
            }
            return false
        }

        sut.startSafariViewControllerRedirectFlow(from: mockVC)

        // dismiss should not be called – SafariVC dismisses itself when Done is tapped
        XCTAssertFalse(sut._dismissPresentedViewControllerCalled)
        XCTAssertTrue(sut._unsubscribeFromNotificationsCalled)
        waitForExpectations(timeout: 2, handler: nil)
    }

    /// After starting a SafariViewController redirect flow,
    /// when SafariViewController fails to load the initial page (on iOS 11+ & without redirects),
    /// RedirectContext's completion block and dismiss method should be called.
    func testSafariViewControllerRedirectFlow_failedInitialLoad_iOS11Plus() {

        let mockVC = MockUIViewController()
        let source = STPFixtures.iDEALSource()
        let exp = expectation(description: "completion")
        let sut = STPRedirectContext(source: source) { sourceID, clientSecret, error in
            XCTAssertEqual(sourceID, source.stripeID)
            XCTAssertEqual(clientSecret, source.clientSecret)
            let expectedError = NSError.stp_genericConnectionError()
            XCTAssertEqual(error! as NSError, expectedError)
            exp.fulfill()
        }!

        sut._handleRedirectCompletionWithErrorHook = { shouldDismissViewController in
            if shouldDismissViewController {
                sut.safariViewControllerDidCompleteDismissal(SFSafariViewController(url: URL(string: "https://www.stripe.com")!))
            }
        }

        mockVC.presentChecker = { vc in
            if vc is SFSafariViewController {
                let sfvc = vc as? SFSafariViewController
                if let sfvc {
                    sfvc.delegate?.safariViewController?(sfvc, didCompleteInitialLoad: false)
                }
                return true
            }
            return false
        }
        sut.startSafariViewControllerRedirectFlow(from: mockVC)

        XCTAssertTrue(sut._unsubscribeFromNotificationsCalled)
        XCTAssertTrue(sut._dismissPresentedViewControllerCalled)

        waitForExpectations(timeout: 2, handler: nil)
    }

    /// After starting a SafariViewController redirect flow,
    /// when SafariViewController fails to load the initial page (on iOS 11+ after redirecting to non-Stripe page),
    /// RedirectContext's completion block should not be called (SFVC keeps loading)
    func testSafariViewControllerRedirectFlow_failedInitialLoadAfterRedirect_iOS11Plus() {
        let mockVC = MockUIViewController()
        let source = STPFixtures.iDEALSource()
        let sut = STPRedirectContext(source: source) { _, _, _ in
            XCTFail("completion called")
        }!

        XCTAssertFalse(sut._unsubscribeFromNotificationsCalled) // move
        XCTAssertFalse(sut._dismissPresentedViewControllerCalled) // move

        sut.startSafariViewControllerRedirectFlow(from: mockVC)

        mockVC.presentChecker = { vc in
            if vc is SFSafariViewController {
                let sfvc = vc as? SFSafariViewController
                // before initial load is done, SFVC was redirected to a non-stripe.com domain
                if let sfvc, let url = URL(string: "https://girogate.de") {
                    sfvc.delegate?.safariViewController?(
                        sfvc,
                        initialLoadDidRedirectTo: url)
                }
                // Tell the delegate that the initial load failed.
                // on iOS 11, with the redirect, this is a no-op
                if let sfvc {
                    sfvc.delegate?.safariViewController?(sfvc, didCompleteInitialLoad: false)
                }
                return true
            }
            return false
        }
        unsubscribeContext(sut)
    }

    /// After starting a SafariViewController redirect flow,
    /// when the RedirectContext is cancelled, its dismiss method should be called.
    func testSafariViewControllerRedirectFlow_cancel() {
        let mockVC = MockUIViewController()
        let source = STPFixtures.iDEALSource()
        let sut = STPRedirectContext(source: source) { _, _, _ in
            XCTFail("completion called")
        }!

        sut.startSafariViewControllerRedirectFlow(from: mockVC)
        sut.cancel()

        XCTAssertTrue(mockVC.presentCalled)
        XCTAssertTrue(sut._unsubscribeFromNotificationsCalled)
        XCTAssertTrue(sut._dismissPresentedViewControllerCalled)
    }

    /// After starting a SafariViewController redirect flow,
    /// if no action is taken, nothing should be called.
    func testSafariViewControllerRedirectFlow_noAction() {
        let mockVC = MockUIViewController()
        let source = STPFixtures.iDEALSource()
        let sut = STPRedirectContext(source: source) { _, _, _ in
            XCTFail("completion called")
        }!

        sut.startSafariViewControllerRedirectFlow(from: mockVC)
        XCTAssertTrue(mockVC.presentCalled)
        XCTAssertFalse(sut._unsubscribeFromNotificationsCalled)
        XCTAssertFalse(sut._dismissPresentedViewControllerCalled)

        unsubscribeContext(sut)
    }

    /// After starting a Safari app redirect flow,
    /// when a DidBecomeActive notification is posted, RedirectContext's completion
    /// block and dismiss method should be called.
    func testSafariAppRedirectFlow_activeNotification() {
        let source = STPFixtures.iDEALSource()
        let exp = expectation(description: "completion")
        let sut = STPRedirectContext(source: source) { sourceID, clientSecret, error in
            XCTAssertEqual(sourceID, source.stripeID)
            XCTAssertEqual(clientSecret, source.clientSecret)
            XCTAssertNil(error)

            exp.fulfill()
        }!

        sut.startSafariAppRedirectFlow()
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(sut._unsubscribeFromNotificationsCalled)
    }

    /// After starting a Safari app redirect flow,
    /// if no notification is posted, nothing should be called.
    func testSafariAppRedirectFlow_noNotification() {
        let source = STPFixtures.iDEALSource()
        let sut = STPRedirectContext(source: source) { _, _, _ in
            XCTFail("completion called")
        }!

        sut.startSafariAppRedirectFlow()
        XCTAssertFalse(sut._unsubscribeFromNotificationsCalled)
        XCTAssertFalse(sut._dismissPresentedViewControllerCalled)

        unsubscribeContext(sut)
    }

    /// If a source type that supports native redirect is used and it contains a native
    /// url, an app to app redirect should attempt to be initiated.
    func testNativeRedirectSupportingSourceFlow_validNativeURL() {
        let source = STPFixtures.alipaySourceWithNativeURL()
        let sourceURL = URL(string: source.details?["native_url"] as! String)!

        let sut = STPRedirectContext(
            source: source) { _, _, _ in
            XCTFail("completion called")
        }!

        XCTAssertNotNil(sut.nativeRedirectURL)
        XCTAssertEqual(sut.nativeRedirectURL, sourceURL)

        let applicationMock = MockUIApplication()
        sut.application = applicationMock
        applicationMock.openHandler = { url, completion in
            XCTAssertTrue(url == sourceURL)
            completion?(true)
        }

        let mockVC = MockUIViewController()
        sut.startRedirectFlow(from: mockVC)
        XCTAssertFalse(sut._startSafariAppRedirectFlowCalled)
        XCTAssertTrue(applicationMock.openCalled)
        sut.unsubscribeFromNotifications()
    }

    /// If a source type that supports native redirect is used and it does not
    /// contain a native url, standard web view redirect should be attempted
    func testNativeRedirectSupportingSourceFlow_invalidNativeURL() {
        let source = STPFixtures.alipaySource()
        let sut = STPRedirectContext(
            source: source) { _, _, _ in
            XCTFail("completion called")
        }!
        XCTAssertNil(sut.nativeRedirectURL)

        let applicationMock = MockUIApplication()
        sut.application = applicationMock

        let mockVC = MockUIViewController()
        mockVC.presentChecker = { $0 is SFSafariViewController }
        sut.startRedirectFlow(from: mockVC)

        let expectation = self.expectation(description: "Waiting 100ms for SafariServices")

        // Hack: Wait ~100ms to call sut back before unsubscribing from notifications. Otherwise the Safari thread doesn't get the unsubscribe request in time and calls the deallocated sut, crashing the app.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            expectation.fulfill()
        })

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertFalse(applicationMock.openCalled)
        XCTAssertTrue(mockVC.presentCalled)
        sut.unsubscribeFromNotifications()
    }

    // MARK: - WeChat Pay

    /// If a WeChat source type is used, we should attempt an app redirect.
    func testWeChatPaySource_appRedirectSucceeds() {
        let source = STPFixtures.weChatPaySource()
        let sourceURL = URL(string: source.weChatPayDetails!.weChatAppURL!)!

        let sut = STPRedirectContext(
            source: source) { _, _, _ in
            XCTFail("completion called")
        }!

        XCTAssertNotNil(sut.nativeRedirectURL)
        XCTAssertEqual(sut.nativeRedirectURL, sourceURL)
        XCTAssertNil(sut.redirectURL)
        XCTAssertNotNil(sut.returnURL)

        let applicationMock = MockUIApplication()
        applicationMock.openHandler = { url, completion in
            XCTAssertEqual(url, sourceURL)
            completion?(true)
        }
        sut.application = applicationMock
        let mockVC = MockUIViewController()
        sut.startRedirectFlow(from: mockVC)
        let expectation = self.expectation(description: "Waiting 100ms for SafariServices")

        // Hack: Wait ~100ms to call sut back before unsubscribing from notifications. Otherwise the Safari thread doesn't get the unsubscribe request in time and calls the deallocated sut, crashing the app.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            expectation.fulfill()
        })

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertFalse(sut._startSafariAppRedirectFlowCalled)
        XCTAssertFalse(sut.isSafariVCPresented())
        XCTAssertTrue(applicationMock.openCalled)
        sut.unsubscribeFromNotifications()
    }

    /// If a WeChat source type is used, we should attempt an app redirect.
    /// If app redirect fails, expect an error.
    func testWeChatPaySource_appRedirectFails() {
        let source = STPFixtures.weChatPaySource()
        let sourceURL = URL(string: source.weChatPayDetails!.weChatAppURL!)!

        let expectation = self.expectation(description: "Completion block called")
        let sut = STPRedirectContext(source: source) { _, _, error in
            guard let error = error as? NSError else {
                XCTFail()
                return
            }
            XCTAssertEqual(error.domain, STPRedirectContext.STPRedirectContextErrorDomain)
            XCTAssertEqual(error.code, STPRedirectContextError.appRedirectError.rawValue)
            expectation.fulfill()
        }!

        XCTAssertNotNil(sut.nativeRedirectURL)
        XCTAssertEqual(sut.nativeRedirectURL, sourceURL)
        XCTAssertNil(sut.redirectURL)
        XCTAssertNotNil(sut.returnURL)

        let applicationMock = MockUIApplication()
        applicationMock.openHandler = { url, completion in
            XCTAssertEqual(url, sourceURL)
            completion?(false)
        }
        sut.application = applicationMock
        let mockVC = MockUIViewController()
        sut.startRedirectFlow(from: mockVC)
        let safariWaitExpectation = self.expectation(description: "Waiting 100ms for SafariServices")

        // Hack: Wait ~100ms to call sut back before unsubscribing from notifications. Otherwise the Safari thread doesn't get the unsubscribe request in time and calls the deallocated sut, crashing the app.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            safariWaitExpectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertFalse(sut._startSafariAppRedirectFlowCalled)
        XCTAssertFalse(sut.isSafariVCPresented())
        XCTAssertTrue(applicationMock.openCalled)
        sut.unsubscribeFromNotifications()
    }
}
