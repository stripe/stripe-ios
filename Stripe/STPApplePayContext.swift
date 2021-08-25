//
//  STPApplePayContext.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import ObjectiveC
import PassKit
@_spi(STP) import StripeCore

/// Implement the required methods of this delegate to supply a PaymentIntent to STPApplePayContext and be notified of the completion of the Apple Pay payment.
/// You may also implement the optional delegate methods to handle shipping methods and shipping address changes e.g. to verify you can ship to the address, or update the payment amount.
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
@objc public protocol STPApplePayContextDelegate: NSObjectProtocol {
    /// Called after the customer has authorized Apple Pay.  Implement this method to call the completion block with the client secret of a PaymentIntent or SetupIntent.
    /// - Parameters:
    ///   - paymentMethod:                 The PaymentMethod that represents the customer's Apple Pay payment method.
    /// If you create the PaymentIntent with confirmation_method=manual, pass `paymentMethod.stripeId` as the payment_method and confirm=true. Otherwise, you can ignore this parameter.
    ///   - paymentInformation:      The underlying PKPayment created by Apple Pay.
    /// If you create the PaymentIntent with confirmation_method=manual, you can collect shipping information using its `shippingContact` and `shippingMethod` properties.
    ///   - completion:                        Call this with the PaymentIntent or SetupIntent client secret, or the error that occurred creating the PaymentIntent or SetupIntent.
    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: STPPaymentMethod,
        paymentInformation: PKPayment,
        completion: @escaping STPIntentClientSecretCompletionBlock
    )

    /// Called after the Apple Pay sheet is dismissed with the result of the payment.
    /// Your implementation could stop a spinner and display a receipt view or error to the customer, for example.
    /// - Parameters:
    ///   - status: The status of the payment
    ///   - error: The error that occurred, if any.
    @objc(applePayContext:didCompleteWithStatus:error:)
    func applePayContext(
        _ context: STPApplePayContext,
        didCompleteWith status: STPPaymentStatus,
        error: Error?
    )

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
    
    /// Called when the user has selected a new payment method. You should inspect the
    /// payment method and must invoke the completion block with an updated array of PKPaymentSummaryItem objects.
    /// @note To maintain privacy, the billing information is anonymized. For example, in the United States it only includes the city, state, and zip code.
    /// Receive full payment and billing information in the paymentInformation passed to `applePayContext:didCreatePaymentMethod:paymentInformation:completion:`
    @objc optional func applePayContext(
        _ context: STPApplePayContext,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler: @escaping (_ update: PKPaymentRequestPaymentMethodUpdate) -> Void
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
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
@objc public class STPApplePayContext: NSObject, PKPaymentAuthorizationControllerDelegate {
    /// Initializes this class.
    /// @note This may return nil if the request is invalid e.g. the user is restricted by parental controls, or can't make payments on any of the request's supported networks
    /// - Parameters:
    ///   - paymentRequest:      The payment request to use with Apple Pay.
    ///   - delegate:                    The delegate.
    @objc(initWithPaymentRequest:delegate:)
    public required init?(paymentRequest: PKPaymentRequest, delegate: STPApplePayContextDelegate?) {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: STPApplePayContext.self)
        if !StripeAPI.canSubmitPaymentRequest(paymentRequest) {
            return nil
        }

        authorizationController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        if authorizationController == nil {
            return nil
        }

        self.delegate = delegate

        super.init()
        authorizationController?.delegate = self
    }

    private var presentationWindow: UIWindow?
    /// Presents the Apple Pay sheet from the specified view controller, starting the payment process.
    /// @note This method should only be called once; create a new instance of STPApplePayContext every time you present Apple Pay.
    /// @deprecated A presenting UIViewController is no longer needed. Use presentApplePay(completion:) instead.
    /// - Parameters:
    ///   - viewController:      The UIViewController instance to present the Apple Pay sheet on
    ///   - completion:               Called after the Apple Pay sheet is presented
    @objc(presentApplePayOnViewController:completion:)
    @available(
        *, deprecated, message: "Use `presentApplePay(completion:)` instead.",
        renamed: "presentApplePay(completion:)"
    )
    public func presentApplePay(
        on viewController: UIViewController, completion: STPVoidBlock? = nil
    ) {
        let window = viewController.viewIfLoaded?.window
        self.presentApplePay(from: window, completion: completion)
    }

    /// Presents the Apple Pay sheet from the key window, starting the payment process.
    /// @note This method should only be called once; create a new instance of STPApplePayContext every time you present Apple Pay.
    /// - Parameters:
    ///   - completion:               Called after the Apple Pay sheet is presented
    @objc(presentApplePayWithCompletion:)
    @available(
        iOSApplicationExtension, unavailable,
        message: "Use `presentApplePay(from:completion:)` in App Extensions."
    )
    @available(
        macCatalystApplicationExtension, unavailable,
        message: "Use `presentApplePay(from:completion:)` in App Extensions."
    )
    public func presentApplePay(completion: STPVoidBlock? = nil) {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        self.presentApplePay(from: window, completion: completion)
    }

    /// Presents the Apple Pay sheet from the specified window, starting the payment process.
    /// @note This method should only be called once; create a new instance of STPApplePayContext every time you present Apple Pay.
    /// - Parameters:
    ///   - window:                   The UIWindow to host the Apple Pay sheet
    ///   - completion:               Called after the Apple Pay sheet is presented
    @objc(presentApplePayFromWindow:withCompletion:)
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

        // This instance must live so that the apple pay sheet is dismissed; until then, the app is effectively frozen.
        objc_setAssociatedObject(
            applePayController, UnsafeRawPointer(&kSTPApplePayContextAssociatedObjectKey), self,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        applePayController.present { (presented) in
            stpDispatchToMainThreadIfNecessary {
                completion?()
            }
        }
    }

    /// The STPAPIClient instance to use to make API requests to Stripe.
    /// Defaults to `STPAPIClient.shared`.
    @objc public var apiClient: STPAPIClient = .shared

    private weak var delegate: STPApplePayContextDelegate?
    @objc var authorizationController: PKPaymentAuthorizationController?
    // Internal state
    private var paymentState: STPPaymentState = .notStarted
    private var error: Error?
    /// YES if the flow cancelled or timed out.  This toggles which delegate method (didFinish or didAuthorize) calls our didComplete delegate method
    private var didCancelOrTimeoutWhilePending = false
    private var didPresentApplePay = false

    /// :nodoc:
    public override func responds(to aSelector: Selector!) -> Bool {
        // STPApplePayContextDelegate exposes methods that map 1:1 to PKPaymentAuthorizationControllerDelegate methods
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
        // We need this type to disambiguate from the other PKACDelegate.didSelect:handler: method
        typealias pkDidSelectShippingMethodSignature = (
            (PKPaymentAuthorizationControllerDelegate) -> (
                PKPaymentAuthorizationController, PKShippingMethod,
                @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
            ) -> Void
        )?
        let pk_didSelectShippingMethod = #selector(
            (PKPaymentAuthorizationControllerDelegate.paymentAuthorizationController(
                _:didSelectShippingMethod:handler:)) as pkDidSelectShippingMethodSignature)
        let stp_didSelectShippingMethod = #selector(
            STPApplePayContextDelegate.applePayContext(_:didSelect:handler:))
        let pk_didSelectShippingContact = #selector(
            PKPaymentAuthorizationControllerDelegate.paymentAuthorizationController(
                _:didSelectShippingContact:handler:))
        let stp_didSelectShippingContact = #selector(
            STPApplePayContextDelegate.applePayContext(_:didSelectShippingContact:handler:))

        return [
            pk_didSelectShippingMethod: stp_didSelectShippingMethod,
            pk_didSelectShippingContact: stp_didSelectShippingContact,
        ]
    }

    func _end() {
        if let authorizationController = authorizationController {
            objc_setAssociatedObject(
                authorizationController, UnsafeRawPointer(&kSTPApplePayContextAssociatedObjectKey),
                nil,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        authorizationController = nil
        delegate = nil
    }

    func _shippingDetails(from payment: PKPayment) -> STPPaymentIntentShippingDetailsParams? {
        guard let address = payment.shippingContact?.postalAddress,
            let name = payment.shippingContact?.name
        else {
            // The shipping address street and name are required parameters for a valid STPPaymentIntentShippingDetailsParams
            return nil
        }

        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: address.street)
        addressParams.city = address.city
        addressParams.state = address.state
        addressParams.country = address.isoCountryCode
        addressParams.postalCode = address.postalCode

        let formatter = PersonNameComponentsFormatter()
        formatter.style = .long
        let shippingParams = STPPaymentIntentShippingDetailsParams(
            address: addressParams, name: formatter.string(from: name))
        shippingParams.phone = payment.shippingContact?.phoneNumber?.stringValue

        return shippingParams
    }

    // MARK: - PKPaymentAuthorizationControllerDelegate
    /// :nodoc:
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
            completion(result)
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
            to: #selector(STPApplePayContextDelegate.applePayContext(_:didSelect:handler:)))
            ?? false
        {
            delegate?.applePayContext?(self, didSelect: shippingMethod, handler: completion)
        }
    }

    /// :nodoc:
    @objc
    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController, didSelectShippingContact contact: PKContact,
        handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        if delegate?.responds(
            to: #selector(
                STPApplePayContextDelegate.applePayContext(_:didSelectShippingContact:handler:))
        ) ?? false {
            delegate?.applePayContext?(self, didSelectShippingContact: contact, handler: completion)
        }
    }
    
    /// :nodoc:
    @objc
    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController, didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        if delegate?.responds(
            to: #selector(
                STPApplePayContextDelegate.applePayContext(_:didSelectPaymentMethod:handler:))
        ) ?? false {
            delegate?.applePayContext?(self, didSelectPaymentMethod: paymentMethod, handler: completion)
        }
    }

    /// :nodoc:
    public func paymentAuthorizationControllerDidFinish(
        _ controller: PKPaymentAuthorizationController
    ) {
        // Note: If you don't dismiss the VC, the UI disappears, the VC blocks interaction, and this method gets called again.
        // Note: This method is called if the user cancels (taps outside the sheet) or Apple Pay times out (empirically 30 seconds)
        switch paymentState {
        case .notStarted:
            controller.dismiss {
                stpDispatchToMainThreadIfNecessary {
                    self.delegate?.applePayContext(
                        self, didCompleteWith: .userCancellation, error: nil)
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
                    self.delegate?.applePayContext(self, didCompleteWith: .error, error: self.error)
                    self._end()
                }
            }
        case .success:
            controller.dismiss {
                stpDispatchToMainThreadIfNecessary {
                    self.delegate?.applePayContext(self, didCompleteWith: .success, error: nil)
                    self._end()
                }
            }
        }
    }

    /// :nodoc:
    public func presentationWindow(for controller: PKPaymentAuthorizationController) -> UIWindow? {
        return presentationWindow
    }

    // MARK: - Helpers
    func _completePayment(
        with payment: PKPayment,
        completion: @escaping (PKPaymentAuthorizationStatus, Error?) -> Void
    ) {
        // Helper to handle annoying logic around "Do I call completion block or dismiss + call delegate?"
        let handleFinalState: ((STPPaymentState, Error?) -> Void) = { state, error in
            switch state {
            case .error:
                self.paymentState = .error
                self.error = error
                if self.didCancelOrTimeoutWhilePending {
                    self.authorizationController?.dismiss {
                        stpDispatchToMainThreadIfNecessary {
                            self.delegate?.applePayContext(
                                self, didCompleteWith: .error, error: self.error)
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
                        stpDispatchToMainThreadIfNecessary {
                            self.delegate?.applePayContext(
                                self, didCompleteWith: .success, error: nil)
                            self._end()
                        }
                    }
                } else {
                    completion(PKPaymentAuthorizationStatus.success, nil)
                }
                return
            case .pending, .notStarted:
                assert(false, "Invalid final state")
                return
            }
        }

        // 1. Create PaymentMethod
        apiClient.createPaymentMethod(with: payment) { paymentMethod, paymentMethodCreationError in
            guard let paymentMethod = paymentMethod, paymentMethodCreationError == nil,
                self.authorizationController != nil
            else {
                handleFinalState(.error, paymentMethodCreationError)
                return
            }

            // 2. Fetch PaymentIntent/SetupIntent client secret from delegate
            self.delegate?.applePayContext(
                self, didCreatePaymentMethod: paymentMethod, paymentInformation: payment
            ) { clientSecret, intentCreationError in
                guard let clientSecret = clientSecret, intentCreationError == nil,
                    self.authorizationController != nil
                else {
                    handleFinalState(.error, intentCreationError)
                    return
                }

                if STPSetupIntentConfirmParams.isClientSecretValid(clientSecret) {
                    // 3a. Retrieve the SetupIntent and see if we need to confirm it client-side
                    self.apiClient.retrieveSetupIntent(withClientSecret: clientSecret) {
                        setupIntent, error in
                        guard let setupIntent = setupIntent, error == nil,
                            self.authorizationController != nil
                        else {
                            handleFinalState(.error, error)
                            return
                        }
                        switch setupIntent.status {
                        case .requiresConfirmation, .requiresAction, .requiresPaymentMethod:
                            // 4a. Confirm the SetupIntent
                            self.paymentState = .pending  // After this point, we can't cancel
                            let confirmParams = STPSetupIntentConfirmParams(
                                clientSecret: clientSecret)
                            confirmParams.paymentMethodID = paymentMethod.stripeId
                            confirmParams.useStripeSDK = true

                            self.apiClient.confirmSetupIntent(with: confirmParams) {
                                (setupIntent, error) in
                                guard let setupIntent = setupIntent, error == nil,
                                    self.authorizationController != nil,
                                    setupIntent.status == .succeeded
                                else {
                                    handleFinalState(.error, error)
                                    return
                                }
                                handleFinalState(.success, nil)
                            }
                        case .succeeded:
                            handleFinalState(.success, nil)
                        case .canceled, .processing, .unknown:
                            handleFinalState(
                                .error,
                                Self.makeUnknownError(
                                    message:
                                        "The SetupIntent is in an unexpected state: \(setupIntent.status)"
                                ))
                        }
                    }
                } else {
                    let paymentIntentClientSecret = clientSecret
                    // 3b. Retrieve the PaymentIntent and see if we need to confirm it client-side
                    self.apiClient.retrievePaymentIntent(
                        withClientSecret: paymentIntentClientSecret
                    ) { paymentIntent, error in
                        guard let paymentIntent = paymentIntent, error == nil,
                            self.authorizationController != nil
                        else {
                            handleFinalState(.error, error)
                            return
                        }
                        if paymentIntent.confirmationMethod == .automatic
                            && (paymentIntent.status == .requiresPaymentMethod
                                || paymentIntent.status == .requiresConfirmation)
                        {
                            // 4b. Confirm the PaymentIntent
                            let paymentIntentParams = STPPaymentIntentParams(
                                clientSecret: paymentIntentClientSecret)
                            paymentIntentParams.paymentMethodId = paymentMethod.stripeId
                            paymentIntentParams.useStripeSDK = NSNumber(value: true)
                            paymentIntentParams.shipping = self._shippingDetails(from: payment)

                            self.paymentState = .pending  // After this point, we can't cancel

                            // We don't use PaymentHandler because we can't handle next actions as-is - we'd need to dismiss the Apple Pay VC.
                            self.apiClient.confirmPaymentIntent(with: paymentIntentParams) {
                                postConfirmPI, confirmError in
                                if let postConfirmPI = postConfirmPI,
                                    postConfirmPI.status == .succeeded
                                        || postConfirmPI.status == .requiresCapture
                                {
                                    handleFinalState(.success, nil)
                                } else {
                                    handleFinalState(.error, confirmError)
                                }
                            }
                        } else if paymentIntent.status == .succeeded
                            || paymentIntent.status == .requiresCapture
                        {
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
        }
    }

    static func makeUnknownError(message: String) -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: NSError.stp_unexpectedErrorMessage(),
            STPError.errorMessageKey: message,
        ]
        return NSError(
            domain: STPPaymentHandler.errorDomain,
            code: STPPaymentHandlerErrorCode.intentStatusErrorCode.rawValue, userInfo: userInfo)
    }
}

/// :nodoc:
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
@_spi(STP) extension STPApplePayContext: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier: String {
        return "STPApplePayContext"
    }
}

private var kSTPApplePayContextAssociatedObjectKey = 0
enum STPPaymentState: Int {
    case notStarted
    case pending
    case error
    case success
}
