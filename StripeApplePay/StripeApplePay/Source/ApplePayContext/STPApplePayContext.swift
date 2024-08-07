//
//  STPApplePayContext.swift
//  StripeApplePay
//
//  Created by Yuki Tokuhiro on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import ObjectiveC
@preconcurrency import PassKit
@_spi(STP) import StripeCore

/// :nodoc:
@objc public protocol _stpinternal_STPApplePayContextDelegateBase: NSObjectProtocol {
    /// Called when the user selects a new shipping method.  The delegate should determine
    /// shipping costs based on the shipping method and either the shipping address supplied in the original
    /// PKPaymentRequest or the address fragment provided by the last call to paymentAuthorizationController:
    /// didSelectShippingContact:completion:.
    /// You must invoke the completion block with an updated array of PKPaymentSummaryItem objects.
    @objc(applePayContext:didSelectShippingMethod:handler:)
    optional func applePayContext(
        _ context: STPApplePayContext,
        didSelect shippingMethod: PKShippingMethod,
        handler: @escaping (_ update: PKPaymentRequestShippingMethodUpdate) -> Void
    )

    /// Called when the user has selected a new shipping address.  You should inspect the
    /// address and must invoke the completion block with an updated array of PKPaymentSummaryItem objects.
    /// @note To maintain privacy, the shipping information is anonymized. For example, in the United States it only includes the city, state, and zip code. This provides enough information to calculate shipping costs, without revealing sensitive information until the user actually approves the purchase.
    /// Receive full shipping information in the paymentInformation passed to `applePayContext:didCreatePaymentMethod:paymentInformation:completion:`
    @objc optional func applePayContext(
        _ context: STPApplePayContext,
        didSelectShippingContact contact: PKContact,
        handler: @escaping (_ update: PKPaymentRequestShippingContactUpdate) -> Void
    )

    /// Called when the user has entered or updated a coupon code. You should validate the
    /// coupon and must invoke the completion block with a PKPaymentRequestCouponCodeUpdate object.
    @available(iOS 15.0, *)
    @objc optional func applePayContext(
        _ context: STPApplePayContext,
        didChangeCouponCode couponCode: String,
        handler completion: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    )

    /// Optionally configure additional information on your PKPaymentAuthorizationResult.
    /// This closure will be called after the PaymentIntent or SetupIntent is confirmed, but before
    /// the Apple Pay sheet has been closed.
    /// In your implementation, you can configure the PKPaymentAuthorizationResult to add custom fields, such as `orderDetails`.
    /// See https://developer.apple.com/documentation/passkit/pkpaymentauthorizationresult for all configuration options.
    /// This method is optional. If you implement this, you must call the handler block with the PKPaymentAuthorizationResult on the main queue.
    /// WARNING: If you do not call the completion handler, your app will hang until the Apple Pay sheet times out.
    @objc optional func applePayContext(
        _ context: STPApplePayContext,
        willCompleteWithResult authorizationResult: PKPaymentAuthorizationResult,
        handler: @escaping (_ authorizationResult: PKPaymentAuthorizationResult) -> Void
    )
}

/// Implement the required methods of this delegate to supply a PaymentIntent to ApplePayContext and be notified of the completion of the Apple Pay payment.
/// You may also implement the optional delegate methods to handle shipping methods and shipping address changes e.g. to verify you can ship to the address, or update the payment amount.
public protocol ApplePayContextDelegate: _stpinternal_STPApplePayContextDelegateBase {
    /// Called after the customer has authorized Apple Pay.  Implement this method to call the completion block with the client secret of a PaymentIntent or SetupIntent.
    /// - Parameters:
    ///   - paymentMethod:                 The PaymentMethod that represents the customer's Apple Pay payment method.
    /// If you create the PaymentIntent with confirmation_method=manual, pass `paymentMethod.id` as the payment_method and confirm=true. Otherwise, you can ignore this parameter.
    ///   - paymentInformation:      The underlying PKPayment created by Apple Pay.
    /// If you create the PaymentIntent with confirmation_method=manual, you can collect shipping information using its `shippingContact` and `shippingMethod` properties.
    ///   - completion:                        Call this with the PaymentIntent or SetupIntent client secret, or the error that occurred creating the PaymentIntent or SetupIntent.
    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment,
        completion: @escaping STPIntentClientSecretCompletionBlock
    )

    /// Called after the Apple Pay sheet is dismissed with the result of the payment.
    /// Your implementation could stop a spinner and display a receipt view or error to the customer, for example.
    /// - Parameters:
    ///   - status: The status of the payment
    ///   - error: The error that occurred, if any.
    func applePayContext(
        _ context: STPApplePayContext,
        didCompleteWith status: STPApplePayContext.PaymentStatus,
        error: Error?
    )
}

/// A helper class that implements Apple Pay.
/// Usage looks like this:
/// 1. Initialize this class with a PKPaymentRequest describing the payment request (amount, line items, required shipping info, etc)
/// 2. Call presentApplePayOnViewController:completion: to present the Apple Pay sheet and begin the payment process
/// 3 (optional): If you need to respond to the user changing their shipping information/shipping method, implement the optional delegate methods
/// 4. When the user taps 'Buy', this class uses the PaymentIntent that you supply in the applePayContext:didCreatePaymentMethod:completion: delegate method to complete the payment
/// 5. After payment completes/errors and the sheet is dismissed, this class informs you in the applePayContext:didCompleteWithStatus: delegate method
/// - seealso: https://stripe.com/docs/apple-pay#native for a full guide
/// - seealso: ApplePayExampleViewController for an example
@MainActor
@objc(STPApplePayContext)
public class STPApplePayContext: NSObject, PKPaymentAuthorizationControllerDelegate, Sendable {
    enum Error: Swift.Error {
        case invalidFinalState
    }
    /// A special string that can be passed in place of a intent client secret to force showing success and return a PaymentState of `success`.
    /// - Note: ⚠️ If provided, the SDK performs no action to complete the payment or setup - it doesn't confirm a PaymentIntent or SetupIntent or handle next actions.
    ///   You should only use this if your integration can't create a PaymentIntent or SetupIntent. It is your responsibility to ensure that you only pass this value if the payment or set up is successful. 
    @_spi(STP) public static let COMPLETE_WITHOUT_CONFIRMING_INTENT = "COMPLETE_WITHOUT_CONFIRMING_INTENT"

    /// Initializes this class.
    /// @note This may return nil if the request is invalid e.g. the user is restricted by parental controls, or can't make payments on any of the request's supported networks
    /// @note If using Swift, using ApplePayContextDelegate is recommended over STPApplePayContextDelegate.
    /// - Parameters:
    ///   - paymentRequest:      The payment request to use with Apple Pay.
    ///   - delegate:                    The delegate.
    @objc(initWithPaymentRequest:delegate:)
    public required init?(
        paymentRequest: PKPaymentRequest,
        delegate: _stpinternal_STPApplePayContextDelegateBase?
    ) {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: STPApplePayContext.self)
        let canMakePayments: Bool = {
            if #available(iOS 15.0, *) {
                // On iOS 15+, Apple Pay can be displayed even though there are no cards because Apple added the ability for customers to add cards in the payment sheet (see WWDC '21 "What's new in Wallet and Apple Pay")
                return PKPaymentAuthorizationController.canMakePayments()
            } else {
                return PKPaymentAuthorizationController.canMakePayments(usingNetworks: StripeAPI.supportedPKPaymentNetworks())
            }
        }()

        assert(!paymentRequest.merchantIdentifier.isEmpty, "You must set `merchantIdentifier` on your payment request.")
        guard
            canMakePayments,
            !paymentRequest.merchantIdentifier.isEmpty,
            // PKPaymentAuthorizationController's docs incorrectly state:
            // "If the user can’t make payments on any of the payment request’s supported networks, initialization fails and this method returns nil."
            // In actuality, this initializer is non-nullable. To make sure we return nil when the request is invalid, we'll use PKPaymentAuthorizationViewController's initializer, which *is* nullable.
            PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) != nil
        else {
            return nil
        }
        authorizationController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)

        self.delegate = delegate

        super.init()
        authorizationController?.delegate = self
    }

    private var presentationWindow: UIWindow?

    /// Presents the Apple Pay sheet from the key window, starting the payment process.
    /// @note This method should only be called once; create a new instance of STPApplePayContext every time you present Apple Pay.
    /// - Parameters:
    ///   - completion:               Called after the Apple Pay sheet is presented
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    @objc(presentApplePayWithCompletion:)
    public func presentApplePay(completion: STPVoidBlock? = nil) {
        #if os(visionOS)
        // This isn't great: We should encourage the use of presentApplePay(from window:) instead.
        let windows = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows }
            .flatMap { $0 }
            .sorted { firstWindow, _ in firstWindow.isKeyWindow }
        let window = windows.first
        #else
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        #endif
        self.presentApplePay(from: window, completion: completion)
    }

    /// Presents the Apple Pay sheet from the specified window, starting the payment process.
    /// @note This method should only be called once; create a new instance of STPApplePayContext every time you present Apple Pay.
    /// - Parameters:
    ///   - window:                   The UIWindow to host the Apple Pay sheet
    ///   - completion:               Called after the Apple Pay sheet is presented
    @objc(presentApplePayFromWindow:completion:)
    public func presentApplePay(from window: UIWindow?, completion: STPVoidBlock? = nil) {
        presentationWindow = window
        guard !didPresentApplePay, let applePayController = self.authorizationController else {
            assert(
                false,
                "This method should only be called once; create a new instance of STPApplePayContext every time you present Apple Pay."
            )
            return
        }
        didPresentApplePay = true

        // This instance (and the associated Objective-C bridge object, if any) must live so
        // that the apple pay sheet is dismissed; until then, the app is effectively frozen.
        objc_setAssociatedObject(
            applePayController,
            UnsafeRawPointer(&kApplePayContextAssociatedObjectKey),
            self,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        applePayController.present { (_) in
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    /// Presents the Apple Pay sheet from the specified view controller, starting the payment process.
    /// @note This method should only be called once; create a new instance of STPApplePayContext every time you present Apple Pay.
    /// @deprecated A presenting UIViewController is no longer needed. Use presentApplePay(completion:) instead.
    /// - Parameters:
    ///   - viewController:      The UIViewController instance to present the Apple Pay sheet on
    ///   - completion:               Called after the Apple Pay sheet is presented
    @objc(presentApplePayOnViewController:completion:)
    @available(
        *,
        deprecated,
        message: "Use `presentApplePay(completion:)` instead.",
        renamed: "presentApplePay(completion:)"
    )
    @MainActor
    public func presentApplePay(
        on viewController: UIViewController,
        completion: STPVoidBlock? = nil
    ) {
        let window = viewController.viewIfLoaded?.window
        presentApplePay(from: window, completion: completion)
    }

    /// The API Client to use to make requests.
    /// Defaults to `STPAPIClient.shared`
    @MainActor @objc public var apiClient: STPAPIClient = STPAPIClient.shared
    /// ApplePayContext passes this to the /confirm endpoint for PaymentIntents if it did not collect shipping details itself.
    /// :nodoc:
    @_spi(STP) public var shippingDetails: StripeAPI.ShippingDetails?
    private weak var delegate: _stpinternal_STPApplePayContextDelegateBase?
    @objc var authorizationController: PKPaymentAuthorizationController?
    @_spi(STP) public var returnUrl: String?

    @_spi(STP) @frozen public enum ConfirmType {
        case client
        case server
        /// The merchant backend used the special string instead of a intent client secret, so we completed the payment without confirming an intent.
        case none
    }
    /// Tracks where the call to confirm the PaymentIntent or SetupIntent happened.
    @_spi(STP) public var confirmType: ConfirmType?
    // Internal state
    private var paymentState: PaymentState = .notStarted
    private var error: Swift.Error?
    /// YES if the flow cancelled or timed out.  This toggles which delegate method (didFinish or didAuthorize) calls our didComplete delegate method
    private var didCancelOrTimeoutWhilePending = false
    private var didPresentApplePay = false

    /// :nodoc:
    @objc public override func responds(to aSelector: Selector!) -> Bool {
        // ApplePayContextDelegate exposes methods that map 1:1 to PKPaymentAuthorizationControllerDelegate methods
        // We want this method to return YES for these methods IFF they are implemented by our delegate

        // Why not simply implement the methods to call their equivalents on self.delegate?
        // The implementation of e.g. didSelectShippingMethod must call the completion block.
        // If the user does not implement e.g. didSelectShippingMethod, we don't know the correct PKPaymentSummaryItems to pass to the completion block
        // (it may have changed since we were initialized due to another delegate method)
        if let equivalentDelegateSelector = _delegateToAppleDelegateMapping()[aSelector] {
            return delegate?.responds(to: equivalentDelegateSelector) ?? false
        } else {
            return super.responds(to: aSelector)
        }
    }

    // MARK: - Private Helper
    func _delegateToAppleDelegateMapping() -> [Selector: Selector] {
        typealias pkDidSelectShippingMethodSignature =
            (any PKPaymentAuthorizationControllerDelegate) -> (
                (
                    PKPaymentAuthorizationController,
                    PKShippingMethod,
                    @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
                ) -> Void
            )?
        let pk_didSelectShippingMethod = #selector(
            (PKPaymentAuthorizationControllerDelegate.paymentAuthorizationController(
                _:
                didSelectShippingMethod:
                handler:
            )) as pkDidSelectShippingMethodSignature)
        let stp_didSelectShippingMethod = #selector(
            _stpinternal_STPApplePayContextDelegateBase.applePayContext(_:didSelect:handler:))
        let pk_didSelectShippingContact = #selector(
            PKPaymentAuthorizationControllerDelegate.paymentAuthorizationController(
                _:
                didSelectShippingContact:
                handler:
            ))
        let stp_didSelectShippingContact = #selector(
            _stpinternal_STPApplePayContextDelegateBase.applePayContext(
                _:
                didSelectShippingContact:
                handler:
            ))

        var delegateToAppleDelegateMapping = [
            pk_didSelectShippingMethod: stp_didSelectShippingMethod,
            pk_didSelectShippingContact: stp_didSelectShippingContact,
        ]

        if #available(iOS 15.0, *) {
            // On iOS 15+, Apple Pay can now accept coupon codes directly, so we need to broker the
            // new coupon delegate functions between the host app and Apple Pay.
            let pk_didChangeCouponCode = #selector(
                PKPaymentAuthorizationControllerDelegate.paymentAuthorizationController(
                    _:
                    didChangeCouponCode:
                    handler:
                ))
            let stp_didChangeCouponCode = #selector(
                _stpinternal_STPApplePayContextDelegateBase.applePayContext(
                    _:
                    didChangeCouponCode:
                    handler:
                ))

            delegateToAppleDelegateMapping[pk_didChangeCouponCode] = stp_didChangeCouponCode
        }

        return delegateToAppleDelegateMapping
    }

    func _end() {
        if let authorizationController = authorizationController {
            objc_setAssociatedObject(
                authorizationController,
                UnsafeRawPointer(&kApplePayContextAssociatedObjectKey),
                nil,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
        authorizationController = nil
        delegate = nil
    }

    func _shippingDetails(from payment: PKPayment) -> StripeAPI.ShippingDetails? {
        guard let address = payment.shippingContact?.postalAddress,
            let name = payment.shippingContact?.name
        else {
            // The shipping address street and name are required parameters for a valid .ShippingDetails
            // Return `shippingDetails` instead
            return shippingDetails
        }

        let addressParams = StripeAPI.ShippingDetails.Address(
            city: address.city,
            country: address.isoCountryCode,
            line1: address.street,
            postalCode: address.postalCode,
            state: address.state
        )

        let formatter = PersonNameComponentsFormatter()
        formatter.style = .long
        let shippingParams = StripeAPI.ShippingDetails(
            address: addressParams,
            name: formatter.string(from: name),
            phone: payment.shippingContact?.phoneNumber?.stringValue
        )

        return shippingParams
    }

    // MARK: - PKPaymentAuthorizationControllerDelegate
    /// :nodoc:
    @objc(paymentAuthorizationController:didAuthorizePayment:handler:)
    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Some observations (on iOS 12 simulator):
        // - The docs say localizedDescription can be shown in the Apple Pay sheet, but I haven't seen this.
        // - If you call the completion block w/ a status of .failure and an error, the user is prompted to try again.

        _completePayment(with: payment) { status, error in
            let errors = [STPAPIClient.pkPaymentError(forStripeError: error)].compactMap({ $0 })
            let result = PKPaymentAuthorizationResult(status: status, errors: errors)
            if self.delegate?.responds(
                to: #selector(
                    _stpinternal_STPApplePayContextDelegateBase.applePayContext(
                        _:
                        willCompleteWithResult:
                        handler:
                    ))
            )
                ?? false
            {
                self.delegate?.applePayContext?(
                    self,
                    willCompleteWithResult: result,
                    handler: { newResult in
                        completion(newResult)
                    }
                )
            } else {
                completion(result)
            }
        }
    }

    /// :nodoc:
    @objc
    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingMethod shippingMethod: PKShippingMethod,
        handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        if delegate?.responds(
            to: #selector(
                _stpinternal_STPApplePayContextDelegateBase.applePayContext(_:didSelect:handler:))
        )
            ?? false
        {
            delegate?.applePayContext?(self, didSelect: shippingMethod, handler: completion)
        }
    }

    /// :nodoc:
    @objc
    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        if delegate?.responds(
            to: #selector(
                _stpinternal_STPApplePayContextDelegateBase.applePayContext(
                    _:
                    didSelectShippingContact:
                    handler:
                ))
        ) ?? false {
            delegate?.applePayContext?(self, didSelectShippingContact: contact, handler: completion)
        }
    }

    /// :nodoc:
    @available(iOS 15.0, *)
    @objc
    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didChangeCouponCode couponCode: String,
        handler completion: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void) {

        if delegate?.responds(
            to: #selector(
                _stpinternal_STPApplePayContextDelegateBase.applePayContext(_:didChangeCouponCode:handler:))
        ) ?? false {
            delegate?.applePayContext?(self, didChangeCouponCode: couponCode, handler: completion)
        }
    }

    /// :nodoc:
    @objc public func paymentAuthorizationControllerDidFinish(
        _ controller: PKPaymentAuthorizationController
    ) {
        // Note: If you don't dismiss the VC, the UI disappears, the VC blocks interaction, and this method gets called again.
        // Note: This method is called if the user cancels (taps outside the sheet) or Apple Pay times out (empirically 30 seconds)
        switch paymentState {
        case .notStarted:
            controller.dismiss {
                stpDispatchToMainThreadIfNecessary {
                    self.callDidCompleteDelegate(status: .userCancellation, error: nil)
                    self._end()
                }
            }
        case .pending:
            // We can't cancel a pending payment. If we dismiss the VC now, the customer might interact with the app and miss seeing the result of the payment - risking a double charge, chargeback, etc.
            // Instead, we'll dismiss and notify our delegate when the payment finishes.
            didCancelOrTimeoutWhilePending = true
        case .error:
            controller.dismiss {
                stpDispatchToMainThreadIfNecessary {
                    self.callDidCompleteDelegate(status: .error, error: self.error)
                    self._end()
                }
            }
        case .success:
            controller.dismiss {
                stpDispatchToMainThreadIfNecessary {
                    self.callDidCompleteDelegate(status: .success, error: nil)
                    self._end()
                }
            }
        }
    }

    /// :nodoc:
    @objc nonisolated public func presentationWindow(
        for controller: PKPaymentAuthorizationController
    ) -> UIWindow? {
        MainActor.assumeIsolated {
            return presentationWindow
        }
    }

    // MARK: - Helpers
    @objc func _completePayment(
        with payment: PKPayment,
        completion: @escaping (PKPaymentAuthorizationStatus, Swift.Error?) -> Void
    ) {
        // Helper to handle annoying logic around "Do I call completion block or dismiss + call delegate?"
        let handleFinalState: ((PaymentState, Swift.Error?) -> Void) = { state, error in
            switch state {
            case .error:
                self.paymentState = .error
                self.error = error
                if self.didCancelOrTimeoutWhilePending {
                    self.authorizationController?.dismiss {
                        DispatchQueue.main.async {
                            self.callDidCompleteDelegate(status: .error, error: self.error)
                            self._end()
                        }
                    }
                } else {
                    completion(PKPaymentAuthorizationStatus.failure, error)
                }
                return
            case .success:
                self.paymentState = .success
                if self.didCancelOrTimeoutWhilePending {
                    self.authorizationController?.dismiss {
                        DispatchQueue.main.async {
                            self.callDidCompleteDelegate(status: .success, error: nil)
                            self._end()
                        }
                    }
                } else {
                    completion(PKPaymentAuthorizationStatus.success, nil)
                }
                return
            case .pending, .notStarted:
                let errorAnalytic = ErrorAnalytic(event: .unexpectedApplePayError,
                                                  error: Error.invalidFinalState)
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                stpAssertionFailure("Invalid final state")
                return
            }
        }

        // 1. Create PaymentMethod
        StripeAPI.PaymentMethod.create(apiClient: apiClient, payment: payment) { result in
            guard let paymentMethod = try? result.get(), self.authorizationController != nil else {
                if case .failure(let error) = result {
                    handleFinalState(.error, error)
                } else {
                    handleFinalState(.error, nil)
                }
                return
            }

            let paymentMethodCompletion: STPIntentClientSecretCompletionBlock = {
                clientSecret,
                intentCreationError in
                guard let clientSecret = clientSecret, intentCreationError == nil,
                    self.authorizationController != nil
                else {
                    handleFinalState(.error, intentCreationError)
                    return
                }

                guard clientSecret != STPApplePayContext.COMPLETE_WITHOUT_CONFIRMING_INTENT else {
                    self.confirmType = STPApplePayContext.ConfirmType.none
                    handleFinalState(.success, nil)
                    return
                }

                if StripeAPI.SetupIntentConfirmParams.isClientSecretValid(clientSecret) {
                    // 3a. Retrieve the SetupIntent and see if we need to confirm it client-side
                    
                    Task {
                        do {
                            let setupIntent = try await StripeAPI.SetupIntent.get(apiClient: self.apiClient, clientSecret: clientSecret)
                            
                            switch setupIntent.status {
                            case .requiresConfirmation, .requiresAction, .requiresPaymentMethod:
                                self.confirmType = .client
                                // 4a. Confirm the SetupIntent
                                self.paymentState = .pending  // After this point, we can't cancel
                                var confirmParams = StripeAPI.SetupIntentConfirmParams(
                                    clientSecret: clientSecret
                                )
                                confirmParams.paymentMethod = paymentMethod.id
                                confirmParams.useStripeSdk = true
                                confirmParams.returnUrl = self.returnUrl

                                let confirmedSetupIntent = try await StripeAPI.SetupIntent.confirm(apiClient: self.apiClient, params: confirmParams)
                                guard self.authorizationController != nil,
                                      confirmedSetupIntent.status == .succeeded
                                else {
                                    if case .failure(let error) = result {
                                        handleFinalState(.error, error)
                                    } else {
                                        handleFinalState(.error, nil)
                                    }
                                    return
                                }
                            case .succeeded:
                                self.confirmType = .server
                                handleFinalState(.success, nil)
                            case .canceled, .processing, .unknown, .unparsable, .none:
                                handleFinalState(
                                    .error,
                                    Self.makeUnknownError(
                                        message:
                                            "The SetupIntent is in an unexpected state: \(setupIntent.status!)"
                                    )
                                )
                            }
                            
                        } catch {
                            handleFinalState(.error, error)
                        }
                    }
                } else {
                    let paymentIntentClientSecret = clientSecret
                    // 3b. Retrieve the PaymentIntent and see if we need to confirm it client-side
                    StripeAPI.PaymentIntent.get(
                        apiClient: self.apiClient,
                        clientSecret: paymentIntentClientSecret
                    ) { result in
                        guard let paymentIntent = try? result.get(),
                            self.authorizationController != nil
                        else {
                            if case .failure(let error) = result {
                                handleFinalState(.error, error)
                            } else {
                                handleFinalState(.error, nil)
                            }
                            return
                        }

                        if paymentIntent.confirmationMethod == .automatic
                            && (paymentIntent.status == .requiresPaymentMethod
                                || paymentIntent.status == .requiresConfirmation)
                        {
                            self.confirmType = .client
                            // 4b. Confirm the PaymentIntent

                            var paymentIntentParams = StripeAPI.PaymentIntentParams(
                                clientSecret: paymentIntentClientSecret
                            )
                            paymentIntentParams.paymentMethod = paymentMethod.id
                            paymentIntentParams.useStripeSdk = true
                            // If a merchant attaches shipping to the PI on their server, the /confirm endpoint will error if we update shipping with a “requires secret key” error message.
                            // To accommodate this, don't attach if our shipping is the same as the PI's shipping
                            if paymentIntent.shipping != self._shippingDetails(from: payment) {
                                paymentIntentParams.shipping = self._shippingDetails(from: payment)
                            }

                            self.paymentState = .pending  // After this point, we can't cancel

                            // We don't use PaymentHandler because we can't handle next actions as-is - we'd need to dismiss the Apple Pay VC.
                            StripeAPI.PaymentIntent.confirm(
                                apiClient: self.apiClient,
                                params: paymentIntentParams
                            ) {
                                result in
                                guard let postConfirmPI = try? result.get(),
                                    postConfirmPI.status == .succeeded
                                        || postConfirmPI.status == .requiresCapture
                                else {
                                    if case .failure(let error) = result {
                                        handleFinalState(.error, error)
                                    } else {
                                        handleFinalState(.error, nil)
                                    }
                                    return
                                }
                                handleFinalState(.success, nil)
                            }
                        } else if paymentIntent.status == .succeeded
                            || paymentIntent.status == .requiresCapture
                        {
                            self.confirmType = .server
                            handleFinalState(.success, nil)
                        } else {
                            let unknownError = Self.makeUnknownError(
                                message:
                                    "The PaymentIntent is in an unexpected state. If you pass confirmation_method = manual when creating the PaymentIntent, also pass confirm = true.  If server-side confirmation fails, double check you are passing the error back to the client."
                            )
                            handleFinalState(.error, unknownError)
                        }
                    }
                }
            }
            // 2. Fetch PaymentIntent/SetupIntent client secret from delegate
            let legacyDelegateSelector = NSSelectorFromString(
                "applePayContext:didCreatePaymentMethod:paymentInformation:completion:"
            )
            if let delegate = self.delegate {
                if let delegate = delegate as? ApplePayContextDelegate {
                    delegate.applePayContext(
                        self,
                        didCreatePaymentMethod: paymentMethod,
                        paymentInformation: payment,
                        completion: paymentMethodCompletion
                    )
                } else if delegate.responds(to: legacyDelegateSelector),
                    let helperClass = NSClassFromString("STPApplePayContextLegacyHelper")
                {
                    let legacyStorage = _stpinternal_ApplePayContextDidCreatePaymentMethodStorage(
                        delegate: delegate,
                        context: self,
                        paymentMethod: paymentMethod,
                        paymentInformation: payment,
                        completion: paymentMethodCompletion
                    )
                    helperClass.performDidCreatePaymentMethod(legacyStorage)
                } else {
                    assertionFailure(
                        "An STPApplePayContext's delegate must conform to ApplePayContextDelegate or STPApplePayContextDelegate."
                    )
                }
            }
        }
    }

    func callDidCompleteDelegate(status: PaymentStatus, error: Swift.Error?) {
        if let delegate = self.delegate {
            if let delegate = delegate as? ApplePayContextDelegate {
                delegate.applePayContext(self, didCompleteWith: status, error: error)
            } else if delegate.responds(
                to: NSSelectorFromString("applePayContext:didCompleteWithStatus:error:")
            ) {
                if let helperClass = NSClassFromString("STPApplePayContextLegacyHelper") {
                    let legacyStorage = _stpinternal_ApplePayContextDidCompleteStorage(
                        delegate: delegate,
                        context: self,
                        status: status,
                        error: error
                    )
                    helperClass.performDidComplete(legacyStorage)
                }
            } else {
                assertionFailure(
                    "An STPApplePayContext's delegate must conform to ApplePayContextDelegate or STPApplePayContextDelegate."
                )
            }
        }

    }

    @_spi(STP) public static func makeUnknownError(message: String) -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: NSError.stp_unexpectedErrorMessage(),
            STPError.errorMessageKey: message,
        ]
        return NSError(
            domain: STPError.STPPaymentHandlerErrorDomain,
            code: STPPaymentHandlerErrorCodeIntentStatusErrorCode,
            userInfo: userInfo
        )
    }

    /// This is STPPaymentHandlerErrorCode.intentStatusErrorCode.rawValue, which we don't want to vend from this framework.
    fileprivate static let STPPaymentHandlerErrorCodeIntentStatusErrorCode = 3

    enum PaymentState {
        case notStarted
        case pending
        case error
        case success
    }

    /// An enum representing the status of a payment requested from the user.
    @frozen public enum PaymentStatus {
        /// The payment succeeded.
        case success
        /// The payment failed due to an unforeseen error, such as the user's Internet connection being offline.
        case error
        /// The user cancelled the payment (for example, by hitting "cancel" in the Apple Pay dialog).
        case userCancellation
    }
}

/// :nodoc:
@_spi(STP) extension STPApplePayContext: STPAnalyticsProtocol {
    @_spi(STP) public nonisolated static var stp_analyticsIdentifier: String {
        return "STPApplePayContext"
    }
}

/// :nodoc:
class ModernApplePayContext: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier: String {
        return "ModernApplePayContext"
    }
}

nonisolated(unsafe) private var kSTPApplePayContextAssociatedObjectKey = 0

enum STPPaymentState: Int {
    case notStarted
    case pending
    case error
    case success
}

private class _stpinternal_STPApplePayContextLegacyHelper: NSObject {
    @objc class func performDidCreatePaymentMethod(
        _ storage: _stpinternal_ApplePayContextDidCreatePaymentMethodStorage
    ) {
        // Placeholder to allow this to be called on AnyObject
    }
    @objc class func performDidComplete(_ storage: _stpinternal_ApplePayContextDidCompleteStorage) {
        // Placeholder to allow this to be called on AnyObject
    }
}

nonisolated(unsafe) private var kApplePayContextAssociatedObjectKey = 0
