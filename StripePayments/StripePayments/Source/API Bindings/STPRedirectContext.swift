//
//  STPRedirectContext.swift
//  StripePayments
//
//  Created by Brian Dorfman on 3/29/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore

/// Error codes specific to `STPRedirectContext`
@objc public enum STPRedirectContextError: Int {
    /// `STPRedirectContext` failed to redirect to the app to complete the payment.
    /// This could be because the app is not installed on the user's device.
    @objc(STPRedirectContextAppRedirectError) case appRedirectError
}

/// Possible states for the redirect context to be in
@objc public enum STPRedirectContextState: Int {
    /// Initialized, but redirect not started.
    case notStarted
    /// Redirect is in progress.
    case inProgress
    /// Redirect has been cancelled programmatically before completing.
    case cancelled
    /// Redirect has completed.
    case completed
}

/// A callback that is executed when the context believes the redirect action has been completed.
/// - Parameters:
///   - sourceID: The stripe id of the source.
///   - clientSecret: The client secret of the source.
///   - error: An error if one occured. Note that a lack of an error does not
/// mean that the action was completed successfully, the presence of one confirms
/// that it was not. Currently the only possible error the context can know about
/// is if SFSafariViewController fails its initial load (e.g. the user has no
/// internet connection, or servers are down).
public typealias STPRedirectContextSourceCompletionBlock = (String, String?, Error?) -> Void
/// A callback that is executed when the context believes the redirect action has been completed.
/// This type has been renamed to `STPRedirectContextSourceCompletionBlock` and deprecated.
public typealias STPRedirectContextCompletionBlock = STPRedirectContextSourceCompletionBlock
/// A callback that is executed when the context believes the redirect action has been completed.
/// @note The STPPaymentIntent originally provided to this class may be out of date,
/// so you should re-fetch it using the clientSecret.
/// - Parameters:
///   - clientSecret: The client secret of the PaymentIntent.
///   - error: An error if one occured. Note that a lack of an error does not
/// mean that the action was completed successfully, the presence of one confirms
/// that it was not. Currently the only possible error the context can know about
/// is if SFSafariViewController fails its initial load (e.g. the user has no
/// internet connection, or servers are down).
public typealias STPRedirectContextPaymentIntentCompletionBlock = (String, Error?) -> Void

// swift-format-ignore: DontRepeatTypeInStaticProperties
/// This is a helper class for handling redirects associated with STPSource and
/// STPPaymentIntents.
/// Init and retain an instance with the Source or PaymentIntent you want to handle,
/// then choose a redirect method. The context will fire the completion handler
/// when the redirect completes.
/// Due to the nature of iOS, very little concrete information can be gained
/// during this process, as all actions take place in either the Safari app
/// or the sandboxed SFSafariViewController class. The context attempts to
/// detect when the user has completed the necessary redirect action by listening
/// for both app foregrounds and url callbacks received in the app delegate.
/// However, it is possible the when the redirect is "completed", the user may
/// have not actually completed the necessary actions to authorize the charge.
/// You should not use either this class, nor `STPAPIClient`, as a way
/// to determine when you should charge the Source or to determine if the redirect
/// was successful. Use Stripe webhooks on your backend server to listen for Source
/// state changes and to make the charge.
/// @note You must retain this instance for the duration of the redirect flow.
/// This class dismisses any presented view controller upon deallocation.
/// See https://stripe.com/docs/sources/best-practices
public class STPRedirectContext: NSObject,
    UIViewControllerTransitioningDelegate, STPSafariViewControllerDismissalDelegate
{

    /// The domain for NSErrors specific to `STPRedirectContext`
    @objc public static let STPRedirectContextErrorDomain = "STPRedirectContextErrorDomain"

    /// The current state of the context.
    @objc public internal(set) var state: STPRedirectContextState = .notStarted

    /// Optional URL for a native app. This is passed directly to `UIApplication openURL:`, and if it fails this class falls back to `redirectURL`
    @objc internal var nativeRedirectURL: URL?
    /// The URL to redirect to, assuming `nativeRedirectURL` is nil or fails to open. Cannot be nil if `nativeRedirectURL` is.
    @objc internal var redirectURL: URL?
    /// The expected `returnURL`, passed to STPURLCallbackHandler
    @objc internal var returnURL: URL?
    /// Completion block to execute when finished redirecting, with optional error parameter.
    @objc internal var completion: STPErrorBlock
    /// Error parameter for completion block.
    @objc internal var completionError: Error?
    /// Hook for testing when unsubscribeFromNotifications is called
    var _unsubscribeFromNotificationsCalled: Bool = false
    /// Hook for testing when dismissPresentedViewController is called
    var _dismissPresentedViewControllerCalled: Bool = false
    /// Hook for testing when dismissPresentedViewController is called
    var _handleRedirectCompletionWithErrorHook: ((Bool) -> Void)?
    /// Hook for testing when startSafariAppRedirectFlowCalled is called
    var _startSafariAppRedirectFlowCalled: Bool = false
    var application: UIApplicationProtocol = UIApplication.shared

    /// Initializer for context from an `STPSource`.
    /// @note You must ensure that the returnURL set up in the created source
    /// correctly goes to your app so that users can be returned once
    /// they complete the redirect in the web broswer.
    /// - Parameters:
    ///   - source: The source that needs user redirect action to be taken.
    ///   - completion: A block to fire when the action is believed to have
    /// been completed.
    /// - Returns: nil if the specified source is not a redirect-flow source. Otherwise
    /// a new context object.
    /// @note Execution of the completion block does not necessarily mean the user
    /// successfully performed the redirect action. You should listen for source status
    /// change webhooks on your backend to determine the result of a redirect.
    @objc public convenience init?(
        source: STPSource,
        completion: @escaping STPRedirectContextSourceCompletionBlock
    ) {

        if (source.flow != .redirect && source.type != .weChatPay)
            || !(source.status == .pending || source.status == .chargeable)
        {
            return nil
        }

        let nativeRedirectURL = Self.nativeRedirectURL(for: source)
        var returnURL = source.redirect?.returnURL

        if source.type == .weChatPay {
            // Construct the returnURL for WeChat Pay:
            //   - nativeRedirectURL looks like "weixin://app/MERCHANT_APP_ID/pay/?..."
            //   - the WeChat app will redirect back using a URL like "MERCHANT_APP_ID://pay/?..."
            let merchantAppID = nativeRedirectURL?.pathComponents[1]
            returnURL = URL(string: "\(merchantAppID ?? "")://pay/")
        }

        self.init(
            nativeRedirectURL: nativeRedirectURL,
            redirectURL: source.redirect?.url,
            return: returnURL
        ) { error in
            completion(source.stripeID, source.clientSecret, error)
        }
        self.source = source
    }

    /// Initializer for context from an `STPPaymentIntent`.
    /// This should be used when the `status` is `STPPaymentIntentStatusRequiresAction`.
    /// If the next action involves a redirect, this init method will return a non-nil object.
    /// - Parameters:
    ///   - paymentIntent: The STPPaymentIntent that needs a redirect.
    ///   - completion: A block to fire when the action is believed to have
    /// been completed.
    /// - Returns: nil if the provided PaymentIntent does not need a redirect. Otherwise
    /// a new context object.
    /// @note Execution of the completion block does not necessarily mean the user
    /// successfully performed the redirect action.
    @objc public convenience init?(
        paymentIntent: STPPaymentIntent,
        completion: @escaping STPRedirectContextPaymentIntentCompletionBlock
    ) {
        guard let redirectURL = paymentIntent.nextAction?.redirectToURL?.url,
            let returnURL = paymentIntent.nextAction?.redirectToURL?.returnURL,
            paymentIntent.status == .requiresAction,
            paymentIntent.nextAction?.type == .redirectToURL
        else {
            return nil
        }

        self.init(
            nativeRedirectURL: nil,
            redirectURL: redirectURL,
            return: returnURL
        ) { error in
            completion(paymentIntent.clientSecret, error)
        }
    }

    /// Starts a redirect flow.
    /// You must ensure that your app delegate listens for  the `returnURL` that you
    /// set on the Stripe object, and forwards it to the Stripe SDK so that the
    /// context can be notified when the redirect is completed and dismiss the
    /// view controller. See `StripeAPI.handleURLCallback(with url:)`
    /// The context will listen for both received URLs and app open notifications
    /// and fire its completion block when either the URL is received, or the next
    /// time the app is foregrounded.
    /// The context will initiate the flow by presenting a SFSafariViewController
    /// instance from the passsed in view controller. If you want more manual control
    /// over the redirect method, you can use `startSafariViewControllerRedirectFlowFromViewController`
    /// or `startSafariAppRedirectFlow`
    /// If the redirect supports a native app, and that app is is installed on the user's
    /// device, this call will do a direct app-to-app redirect instead of showing
    /// a web url.
    /// @note This method does nothing if the context is not in the
    /// `STPRedirectContextStateNotStarted` state.
    /// - Parameter presentingViewController: The view controller to present the Safari
    /// view controller from.
    @objc(startRedirectFlowFromViewController:) public func startRedirectFlow(
        from presentingViewController: UIViewController
    ) {

        if state == .notStarted {
            state = .inProgress
            subscribeToURLAndAppActiveNotifications()

            weak var weakSelf = self
            performAppRedirectIfPossible(withCompletion: { success in
                if success {
                    return
                }

                let strongSelf = weakSelf
                if strongSelf == nil {
                    return
                }
                // Redirect failed...
                if strongSelf?.source?.type == .weChatPay {
                    // ...and this Source doesn't support web-based redirect — finish with an error.
                    let error = NSError(
                        domain: STPRedirectContext.STPRedirectContextErrorDomain,
                        code: STPRedirectContextError.appRedirectError.rawValue,
                        userInfo: [
                            NSLocalizedDescriptionKey: NSError.stp_unexpectedErrorMessage(),
                            STPError.errorMessageKey:
                                "Redirecting to WeChat failed. Only offer WeChat Pay if the WeChat app is installed.",
                        ]
                    )
                    stpDispatchToMainThreadIfNecessary({
                        strongSelf?.handleRedirectCompletionWithError(
                            error,
                            shouldDismissViewController: false
                        )
                    })
                } else {
                    // ...reset our state and try a web redirect
                    strongSelf?.state = .notStarted
                    strongSelf?.unsubscribeFromNotifications()
                    strongSelf?.startSafariViewControllerRedirectFlow(
                        from: presentingViewController
                    )
                }
            })
        }
    }

    /// Starts a redirect flow by presenting an SFSafariViewController in your app
    /// from the passed in view controller.
    /// You must ensure that your app delegate listens for  the `returnURL` that you
    /// set on the Stripe object, and forwards it to the Stripe SDK so that the
    /// context can be notified when the redirect is completed and dismiss the
    /// view controller. See `StripeAPI.handleStripeURLCallback(with url:)]`
    /// The context will listen for both received URLs and app open notifications
    /// and fire its completion block when either the URL is received, or the next
    /// time the app is foregrounded.
    /// @note This method does nothing if the context is not in the
    /// `STPRedirectContextStateNotStarted` state.
    /// - Parameter presentingViewController: The view controller to present the Safari
    /// view controller from.
    @objc(startSafariViewControllerRedirectFlowFromViewController:)
    public dynamic func startSafariViewControllerRedirectFlow(
        from presentingViewController: UIViewController
    ) {
        guard let redirectURL = redirectURL else {
            return
        }
        if state == .notStarted {
            state = .inProgress
            subscribeToURLNotifications()
            lastKnownSafariVCURL = redirectURL
            let safariVC = SFSafariViewController(url: lastKnownSafariVCURL!)
            safariVC.transitioningDelegate = self
            #if !canImport(CompositorServices)
            safariVC.delegate = self
            #endif
            safariVC.modalPresentationStyle = .custom
            self.safariVC = safariVC
            presentingViewController.present(
                safariVC,
                animated: true
            )
        }
    }

    /// Starts a redirect flow by calling `openURL` to bounce the user out to
    /// the Safari app.
    /// The context will listen for app open notifications and fire its completion
    /// block the next time the user re-opens the app (either manually or via url)
    /// @note This method does nothing if the context is not in the
    /// `STPRedirectContextStateNotStarted` state.
    @objc
    public func startSafariAppRedirectFlow() {
        _startSafariAppRedirectFlowCalled = true
        guard let redirectURL = redirectURL else {
            return
        }
        if state == .notStarted {
            state = .inProgress
            subscribeToURLAndAppActiveNotifications()
            application._open(redirectURL, options: [:], completionHandler: nil)
        }
    }

    /// Dismisses any presented views and stops listening for any
    /// app opens or callbacks. The completion block will not be fired.
    @objc
    public func cancel() {
        if state == .inProgress {
            state = .cancelled
            unsubscribeFromNotificationsAndDismissPresentedViewControllers()
        }
    }

    private var safariVC: SFSafariViewController?
    /// If we're on iOS 11+ and in the SafariVC flow, this tracks the latest URL loaded/redirected to during the initial load
    private var lastKnownSafariVCURL: URL?
    private var source: STPSource?
    private var subscribedToURLNotifications = false
    private var subscribedToAppActiveNotifications = false

    /// Failable initializer for the general case of STPRedirectContext, some URLs and a completion block.
    init?(
        nativeRedirectURL: URL?,
        redirectURL: URL?,
        return returnURL: URL?,
        completion: @escaping STPErrorBlock
    ) {
        if nativeRedirectURL == nil && redirectURL == nil {
            return nil
        }

        self.nativeRedirectURL = nativeRedirectURL
        self.redirectURL = redirectURL
        self.returnURL = returnURL
        self.completion = completion
        super.init()

        subscribedToURLNotifications = false
        subscribedToAppActiveNotifications = false
    }

    deinit {
        unsubscribeFromNotificationsAndDismissPresentedViewControllers()
    }

    // MARK: - UIViewControllerTransitioningDelegate
    /// :nodoc:
    @objc
    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let controller = STPSafariViewControllerPresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
        controller.dismissalDelegate = self
        return controller
    }

    // MARK: - Private methods -
    func performAppRedirectIfPossible(withCompletion onCompletion: @escaping STPBoolCompletionBlock)
    {

        let nativeURL = nativeRedirectURL
        if nativeURL == nil {
            onCompletion(false)
            return
        }

        if let nativeURL = nativeURL {
            application._open(
                nativeURL,
                options: [:],
                completionHandler: { success in
                    onCompletion(success)
                }
            )
        }
    }

    @objc func handleDidBecomeActiveNotification() {
        // Always `dispatch_async` the `handleDidBecomeActiveNotification` function
        // call to re-queue the task at the end of the run loop. This is so that the
        // `handleURLCallback` gets handled first.
        //
        // Verified this works even if `handleURLCallback` performs `dispatch_async`
        // but not completely sure why :)
        //
        // When returning from a `startSafariAppRedirectFlow` call, the
        // `UIApplicationDidBecomeActiveNotification` handler and
        // `STPURLCallbackHandler` compete. The problem is the
        // `UIApplicationDidBecomeActiveNotification` handler is always queued
        // first causing the `STPURLCallbackHandler` to always fail because the
        // registered callback was already unregistered by the
        // `UIApplicationDidBecomeActiveNotification` handler. We are patching
        // this so that the`STPURLCallbackHandler` can succeed and the
        // `UIApplicationDidBecomeActiveNotification` handler can silently fail.
        DispatchQueue.main.async(execute: {
            self.handleRedirectCompletionWithError(
                nil,
                shouldDismissViewController: true
            )
        })
    }

    @objc dynamic func handleRedirectCompletionWithError(
        _ error: Error?,
        shouldDismissViewController: Bool
    ) {
        if state != .inProgress {
            return
        }

        state = .completed

        unsubscribeFromNotifications()

        if isSafariVCPresented() {
            // SafariVC dismissal delegate will manage calling completion handler
            completionError = error
        } else {
            completion(error)
        }

        if shouldDismissViewController {
            dismissPresentedViewController()
        }
        _handleRedirectCompletionWithErrorHook?(shouldDismissViewController)
    }

    func subscribeToURLNotifications() {
        guard let returnURL = returnURL else {
            return
        }
        if !subscribedToURLNotifications {
            subscribedToURLNotifications = true
            STPURLCallbackHandler.shared().register(
                self,
                for: returnURL
            )
        }
    }

    func subscribeToURLAndAppActiveNotifications() {
        subscribeToURLNotifications()
        if !subscribedToAppActiveNotifications {
            subscribedToAppActiveNotifications = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleDidBecomeActiveNotification),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
    }

    func unsubscribeFromNotificationsAndDismissPresentedViewControllers() {
        unsubscribeFromNotifications()
        dismissPresentedViewController()
    }

    @objc dynamic func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        STPURLCallbackHandler.shared().unregisterListener(self)
        subscribedToURLNotifications = false
        subscribedToAppActiveNotifications = false
        _unsubscribeFromNotificationsCalled = true
    }

    @objc dynamic func dismissPresentedViewController() {
        if isSafariVCPresented() {
            safariVC?.presentingViewController?.dismiss(
                animated: true
            )
            safariVC = nil
        }
        _dismissPresentedViewControllerCalled = true
    }

    // MARK: - STPSafariViewControllerDismissalDelegate -
    func safariViewControllerDidCompleteDismissal(_ controller: SFSafariViewController) {
        completion(completionError)
        completionError = nil
    }

    func isSafariVCPresented() -> Bool {
        return safariVC != nil
    }

    class func nativeRedirectURL(for source: STPSource) -> URL? {
        var nativeURLString: String?
        switch source.type {
        case .alipay:
            nativeURLString = source.details?["native_url"] as? String
        case .weChatPay:
            nativeURLString = source.weChatPayDetails?.weChatAppURL
        default:
            // All other sources currently have no native url support
            break
        }

        let nativeURL = nativeURLString != nil ? URL(string: nativeURLString ?? "") : nil
        return nativeURL
    }
}

/// :nodoc:
@_spi(STP) extension STPRedirectContext: STPURLCallbackListener {
    /// :nodoc:
    @_spi(STP) public func handleURLCallback(_ url: URL) -> Bool {
        stpDispatchToMainThreadIfNecessary({
            self.handleRedirectCompletionWithError(
                nil,
                shouldDismissViewController: true
            )
        })
        // We handle all returned urls that match what we registered for
        return true
    }
}

@objc protocol STPSafariViewControllerDismissalDelegate: NSObjectProtocol {
    func safariViewControllerDidCompleteDismissal(_ controller: SFSafariViewController)
}

typealias STPBoolCompletionBlock = (Bool) -> Void
// SFSafariViewController sometimes manages its own dismissal and does not currently provide
// any easier API hooks to detect when the dismissal has completed. This machinery exists to
// insert ourselves into the View Controller transitioning process and detect when a dismissal
// transition has completed.
class STPSafariViewControllerPresentationController: UIPresentationController {
    weak var dismissalDelegate: STPSafariViewControllerDismissalDelegate?

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if presentedViewController is SFSafariViewController {
            if let presentedViewController = presentedViewController as? SFSafariViewController {
                dismissalDelegate?.safariViewControllerDidCompleteDismissal(presentedViewController)
            }
        }
        return super.dismissalTransitionDidEnd(completed)
    }
}

protocol UIApplicationProtocol {
    func _open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler: ((Bool) -> Void)?)
}

extension UIApplication: UIApplicationProtocol {
    func _open(_ url: URL, options: [OpenExternalURLOptionsKey: Any], completionHandler completion: ((Bool) -> Void)?) {
        open(url, options: options, completionHandler: completion)
    }
}

#if !canImport(CompositorServices)
extension STPRedirectContext: SFSafariViewControllerDelegate {
    // MARK: - SFSafariViewControllerDelegate -
    /// :nodoc:
    @objc
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        var manuallyClosedError: Error?
        if returnURL != nil && state == .inProgress && completionError == nil {
            manuallyClosedError = NSError(
                domain: STPError.stripeDomain,
                code: STPErrorCode.cancellationError.rawValue,
                userInfo: [
                    STPError.errorMessageKey:
                        "User manually closed SFSafariViewController before redirect was completed.",
                ]
            )
        }
        stpDispatchToMainThreadIfNecessary({
            self.handleRedirectCompletionWithError(
                manuallyClosedError,
                shouldDismissViewController: false
            )
        })
    }

    /// :nodoc:
    @objc
    public func safariViewController(
        _ controller: SFSafariViewController,
        didCompleteInitialLoad didLoadSuccessfully: Bool
    ) {
        //     SafariVC is, imo, over-eager to report errors. The way that (for example) girogate.de redirects
        //     can cause SafariVC to report that the initial load failed, even though it completes successfully.
        //
        //     So, only report failures to complete the initial load if the host was a Stripe domain.
        //     Stripe uses 302 redirects, and this should catch local connection problems as well as
        //     server-side failures from Stripe.
        if didLoadSuccessfully == false {
            stpDispatchToMainThreadIfNecessary({
                if self.lastKnownSafariVCURL?.host?.contains("stripe.com") ?? false {
                    self.handleRedirectCompletionWithError(
                        NSError.stp_genericConnectionError(),
                        shouldDismissViewController: true
                    )
                }
            })
        }
    }

    /// :nodoc:
    @objc
    public func safariViewController(
        _ controller: SFSafariViewController,
        initialLoadDidRedirectTo URL: URL
    ) {
        stpDispatchToMainThreadIfNecessary({
            // This is only kept up to date during the "initial load", but we only need the value in
            // `safariViewController:didCompleteInitialLoad:`, so that's fine.
            self.lastKnownSafariVCURL = URL
        })
    }
}
#endif
