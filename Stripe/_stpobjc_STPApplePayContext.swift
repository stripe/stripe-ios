//
//  _stpobjc_STPApplePayContext.swift
//  StripeiOS
//
//  Created by David Estes on 11/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

// This is a workaround for the lack of cross-Swift-module extension support in
// the iOS 11 and iOS 12 Objective-C runtime.

import Foundation
import PassKit
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeApplePay

/*
 NOTE: Because '@objc' is not supported in cross-module extensions below iOS 13, a separate
 Objective-C compatible wrapper of `STPApplePayContext` is needed. When updating
 documentation comments, make sure to update the corresponding comments in
 `STPApplePayContext` as well.
 */

/// A helper class used to bridge StripeApplePay.framework with the legacy Stripe.framework objects.
@objc(STPApplePayContextLegacyHelper)
class STPApplePayContextLegacyHelper: NSObject {
    @objc class func performDidCreatePaymentMethod(_ storage: _stpinternal_ApplePayContextDidCreatePaymentMethodStorage) {
        let delegate = storage.delegate as! STPApplePayContextDelegate
        // Convert the PaymentMethod to an STPPaymentMethod:
        guard let stpPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: storage.paymentMethod.allResponseFields) else {
            assertionFailure("Failed to convert PaymentMethod to STPPaymentMethod")
            return
        }
        delegate.applePayContext(storage.context, didCreatePaymentMethod: stpPaymentMethod, paymentInformation: storage.paymentInformation, completion: storage.completion)
    }
    
    @objc class func performDidComplete(_ storage: _stpinternal_ApplePayContextDidCompleteStorage) {
        let delegate = storage.delegate as! STPApplePayContextDelegate
        let stpStatus = STPPaymentStatus(applePayStatus: storage.status)
        
        // If this is a modern API error, convert it down to a legacy STPError.
        // This is to avoid changing the API experience for users.
        // We can re-evaluate this as we release more of the modern API.
        if let modernError = storage.error as? StripeError {
            storage.error = NSError.stp_error(from: modernError)
        }
        
        delegate.applePayContext(storage.context, didCompleteWith: stpStatus, error: storage.error)
    }

}

/// Implement the required methods of this delegate to supply a PaymentIntent to STPApplePayContext and be notified of the completion of the Apple Pay payment.
/// You may also implement the optional delegate methods to handle shipping methods and shipping address changes e.g. to verify you can ship to the address, or update the payment amount.
@objc(_stpinternal_apContextDelegate)
public protocol STPApplePayContextDelegate: _stpinternal_STPApplePayContextDelegateBase {
    /// Called after the customer has authorized Apple Pay.  Implement this method to call the completion block with the client secret of a PaymentIntent or SetupIntent.
    /// - Parameters:
    ///   - paymentMethod:                 The PaymentMethod that represents the customer's Apple Pay payment method.
    /// If you create the PaymentIntent with confirmation_method=manual, pass `paymentMethod.stripeId` as the payment_method and confirm=true. Otherwise, you can ignore this parameter.
    ///   - paymentInformation:      The underlying PKPayment created by Apple Pay.
    /// If you create the PaymentIntent with confirmation_method=manual, you can collect shipping information using its `shippingContact` and `shippingMethod` properties.
    ///   - completion:                        Call this with the PaymentIntent or SetupIntent client secret, or the error that occurred creating the PaymentIntent or SetupIntent.
    @objc(applePayContext:didCreatePaymentMethod:paymentInformation:completion:)
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
}

/// Implement the required methods of this delegate to supply a PaymentIntent to STPApplePayContext and be notified of the completion of the Apple Pay payment.
/// You may also implement the optional delegate methods to handle shipping methods and shipping address changes e.g. to verify you can ship to the address, or update the payment amount.
/// :nodoc:
@objc(STPApplePayContextDelegate) public protocol _stpobjc_APContextDelegate: NSObjectProtocol {
    /// Called after the customer has authorized Apple Pay.  Implement this method to call the completion block with the client secret of a PaymentIntent or SetupIntent.
    /// - Parameters:
    ///   - paymentMethod:                 The PaymentMethod that represents the customer's Apple Pay payment method.
    /// If you create the PaymentIntent with confirmation_method=manual, pass `paymentMethod.stripeId` as the payment_method and confirm=true. Otherwise, you can ignore this parameter.
    ///   - paymentInformation:      The underlying PKPayment created by Apple Pay.
    /// If you create the PaymentIntent with confirmation_method=manual, you can collect shipping information using its `shippingContact` and `shippingMethod` properties.
    ///   - completion:                        Call this with the PaymentIntent or SetupIntent client secret, or the error that occurred creating the PaymentIntent or SetupIntent.
    @objc(applePayContext:didCreatePaymentMethod:paymentInformation:completion:)
    func applePayContext(
        _ context: _stpobjc_APContext,
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
        _ context: _stpobjc_APContext,
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
        _ context: _stpobjc_APContext,
        didSelect shippingMethod: PKShippingMethod,
        handler: @escaping (_ update: PKPaymentRequestShippingMethodUpdate) -> Void
    )

    /// Called when the user has selected a new shipping address.  You should inspect the
    /// address and must invoke the completion block with an updated array of PKPaymentSummaryItem objects.
    /// @note To maintain privacy, the shipping information is anonymized. For example, in the United States it only includes the city, state, and zip code. This provides enough information to calculate shipping costs, without revealing sensitive information until the user actually approves the purchase.
    /// Receive full shipping information in the paymentInformation passed to `applePayContext:didCreatePaymentMethod:paymentInformation:completion:`
    @objc optional func applePayContext(
        _ context: _stpobjc_APContext,
        didSelectShippingContact contact: PKContact,
        handler: @escaping (_ update: PKPaymentRequestShippingContactUpdate) -> Void
    )
}


class STPApplePayContextBridgeDelegate: NSObject, STPApplePayContextDelegate {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: STPPaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        objcDelegate?.applePayContext(.init(applePayContext: context), didCreatePaymentMethod: paymentMethod, paymentInformation: paymentInformation, completion: completion)
    }
    
    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?) {
        objcDelegate?.applePayContext(.init(applePayContext: context), didCompleteWith: status, error: error)
    }
    
    func applePayContext(_ context: STPApplePayContext, didSelect shippingMethod: PKShippingMethod, handler: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void) {
        objcDelegate?.applePayContext?(.init(applePayContext: context), didSelect: shippingMethod, handler: handler)
    }
    
    func applePayContext(_ context: STPApplePayContext, didSelectShippingContact contact: PKContact, handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void) {
        objcDelegate?.applePayContext?(.init(applePayContext: context), didSelectShippingContact: contact, handler: handler)
    }
    
    /// :nodoc:
    public override func responds(to aSelector: Selector!) -> Bool {
        // Pass through responds(to:) so that we only respond to the shipping/contact
        // messages if the underlying delegate also does so.
        return objcDelegate?.responds(to: aSelector) ?? false
    }
    
    weak var objcDelegate: _stpobjc_APContextDelegate?
    
    init?(delegate: _stpobjc_APContextDelegate?) {
        if let delegate = delegate {
            self.objcDelegate = delegate
        } else {
            return nil
        }
    }
    
}

/// An Objective-C bridge for STPApplePayContext.
/// :nodoc:
@objc(STPApplePayContext)
public class _stpobjc_APContext: NSObject {
    @objc var _applePayContext: STPApplePayContext
    
    /// Initializes this class.
    /// @note This may return nil if the request is invalid e.g. the user is restricted by parental controls, or can't make payments on any of the request's supported networks
    /// - Parameters:
    ///   - paymentRequest:      The payment request to use with Apple Pay.
    ///   - delegate:                    The delegate.
    @objc(initWithPaymentRequest:delegate:)
    public required init?(paymentRequest: PKPaymentRequest, delegate: _stpobjc_APContextDelegate?) {
        bridgeDelegate = STPApplePayContextBridgeDelegate(delegate: delegate)
        guard let context = STPApplePayContext(paymentRequest: paymentRequest, delegate: bridgeDelegate) else {
            return nil
        }
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: Self.self)
        _applePayContext = context
        super.init()
        context.applePayContextObjCBridge = self
    }
    
    // We want to maintain a strong reference to this bridge delegate,
    // which contains a weak reference to the underlying Objective-C delegate.
    var bridgeDelegate: STPApplePayContextBridgeDelegate?
    
    internal init(applePayContext: STPApplePayContext) {
        _applePayContext = applePayContext
    }

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
        _applePayContext.presentApplePay(on: viewController, completion: completion)
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
        _applePayContext.presentApplePay(completion: completion)
    }

    /// Presents the Apple Pay sheet from the specified window, starting the payment process.
    /// @note This method should only be called once; create a new instance of STPApplePayContext every time you present Apple Pay.
    /// - Parameters:
    ///   - window:                   The UIWindow to host the Apple Pay sheet
    ///   - completion:               Called after the Apple Pay sheet is presented
    @objc(presentApplePayFromWindow:withCompletion:)
    public func presentApplePay(from window: UIWindow?, completion: STPVoidBlock? = nil) {
        _applePayContext.presentApplePay(from: window, completion: completion)
    }
    
    /// The STPAPIClient instance to use to make API requests to Stripe.
    /// Defaults to `STPAPIClient.shared`.
    @available(swift, deprecated: 0.0.1, renamed: "apiClient")
    @objc(apiClient) public var _objc_apiClient: _stpobjc_STPAPIClient {
        get {
            _stpobjc_STPAPIClient(apiClient: _applePayContext.apiClient)
        }
        set {
            _applePayContext.apiClient = newValue._apiClient
        }
    }
}

/// :nodoc:
@_spi(STP) extension _stpobjc_APContext: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier = "objc_STPApplePayContext"
}
