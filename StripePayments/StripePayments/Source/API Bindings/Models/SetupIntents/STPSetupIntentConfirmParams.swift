//
//  STPSetupIntentConfirmParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters to confirm a SetupIntent object.
/// For example, you would confirm a SetupIntent when a customer hits the “Save” button on a payment method management view in your app.
/// If the selected payment method does not require any additional steps from the customer, the SetupIntent's status will transition to `STPSetupIntentStatusSucceeded`.  Otherwise, it will transition to `STPSetupIntentStatusRequiresAction`, and suggest additional actions via `nextAction`.
/// Instead of passing this to `STPAPIClient.confirmSetupIntent(...)` directly, we recommend using `STPPaymentHandler` to handle any additional steps for you.
/// - seealso: https://stripe.com/docs/api/setup_intents/confirm
public class STPSetupIntentConfirmParams: NSObject, NSCopying, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Initialize this `STPSetupIntentConfirmParams` with a `clientSecret`.
    /// - Parameter clientSecret: the client secret for this SetupIntent
    @objc
    public init(
        clientSecret: String
    ) {
        self.clientSecret = clientSecret
        super.init()
        additionalAPIParameters = [:]
    }

    /// Initialize this `STPSetupIntentConfirmParams` with a `clientSecret` and `paymentMethodType`.
    /// Use this initializer for SetupIntents that already have a PaymentMethod attached.
    /// - Parameter clientSecret: the client secret for this SetupIntent
    /// - Parameter paymentMethodType: the known type of the SetupIntent's attached PaymentMethod
    @objc
    public init(
        clientSecret: String,
        paymentMethodType: STPPaymentMethodType
    ) {
        self.clientSecret = clientSecret
        self._paymentMethodType = paymentMethodType
        super.init()
        additionalAPIParameters = [:]
    }

    /// The client secret of the SetupIntent. Required.
    @objc public var clientSecret: String
    /// Provide a supported `STPPaymentMethodParams` object, and Stripe will create a
    /// PaymentMethod during PaymentIntent confirmation.
    /// @note alternative to `paymentMethodId`
    @objc public var paymentMethodParams: STPPaymentMethodParams?
    /// Provide an already created PaymentMethod's id, and it will be used to confirm the SetupIntent.
    /// @note alternative to `paymentMethodParams`
    @objc public var paymentMethodID: String?
    /// `@YES` to set this PaymentIntent’s PaymentMethod as the associated Customer's default
    /// This should be a boolean NSNumber, so that it can be `nil`
    @objc @_spi(STP) public var setAsDefaultPM: NSNumber?
    /// The URL to redirect your customer back to after they authenticate or cancel
    /// their payment on the payment method’s app or site.
    /// This should probably be a URL that opens your iOS app.
    @objc public var returnURL: String?
    /// A boolean number to indicate whether you intend to use the Stripe SDK's functionality to handle any SetupIntent next actions.
    /// If set to false, STPSetupIntent.nextAction will only ever contain a redirect url that can be opened in a webview or mobile browser.
    /// When set to true, the nextAction may contain information that the Stripe SDK can use to perform native authentication within your
    /// app.
    @objc public var useStripeSDK: NSNumber?
    /// Details about the Mandate to create.
    /// @note If this value is null, the SDK will set this to an internal value indicating that the mandate data should be inferred from the current context if it's required for `self.paymentMethodType`
    @objc public var mandateData: STPMandateDataParams? {
        get {
            if let _mandateData = _mandateData {
                return _mandateData
            }
            switch paymentMethodType {
            case .AUBECSDebit, .bacsDebit, .bancontact, .iDEAL, .SEPADebit, .EPS, .sofort, .link, .USBankAccount,
                    .cashApp, .payPal, .revolutPay, .klarna, .amazonPay:
                return .makeWithInferredValues()
            default: break
            }
            return nil
        }
        set(newMandateData) {
            _mandateData = newMandateData
        }
    }
    private var _mandateData: STPMandateDataParams?

    internal var _paymentMethodType: STPPaymentMethodType?
    @_spi(STP) public var paymentMethodType: STPPaymentMethodType? {
        if let type = _paymentMethodType {
            return type
        }
        return paymentMethodParams?.type
    }

    override convenience init() {
        // Not a valid clientSecret, but at least it'll be non-null
        self.init(clientSecret: "")
    }

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPSetupIntentConfirmParams.self), self),
            // SetupIntentParams details (alphabetical)
            "clientSecret = \(((clientSecret.count) > 0) ? "<redacted>" : "")",
            "returnURL = \(returnURL ?? "")",
            "paymentMethodId = \(paymentMethodID ?? "")",
            "paymentMethodParams = \(String(describing: paymentMethodParams))",
            "useStripeSDK = \(useStripeSDK ?? 0)",
            // Set as default payment method
            "setAsDefaultPM = \(setAsDefaultPM ?? 0)",
            // Mandate
            "mandateData = \(String(describing: mandateData))",
            // Additional params set by app
            "additionalAPIParameters = \(additionalAPIParameters )",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - NSCopying
    /// :nodoc:
    @objc
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = STPSetupIntentConfirmParams()

        copy.clientSecret = clientSecret
        copy._paymentMethodType = _paymentMethodType
        copy.paymentMethodParams = paymentMethodParams
        copy.paymentMethodID = paymentMethodID
        copy.setAsDefaultPM = setAsDefaultPM
        copy.returnURL = returnURL
        copy.useStripeSDK = useStripeSDK
        copy.mandateData = mandateData
        copy.additionalAPIParameters = additionalAPIParameters

        return copy
    }

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return nil
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: clientSecret)): "client_secret",
            NSStringFromSelector(#selector(getter: paymentMethodParams)): "payment_method_data",
            NSStringFromSelector(#selector(getter: paymentMethodID)): "payment_method",
            NSStringFromSelector(#selector(getter: setAsDefaultPM)): "set_as_default_payment_method",
            NSStringFromSelector(#selector(getter: returnURL)): "return_url",
            NSStringFromSelector(#selector(getter: useStripeSDK)): "use_stripe_sdk",
            NSStringFromSelector(#selector(getter: mandateData)): "mandate_data",
        ]
    }

    // MARK: - Utilities
    static private let regex = try! NSRegularExpression(
        pattern: "^seti_[^_]+_secret_[^_]+$",
        options: []
    )
    @_spi(STP) public static func isClientSecretValid(_ clientSecret: String) -> Bool {
        return
            (regex.numberOfMatches(
                in: clientSecret,
                options: .anchored,
                range: NSRange(location: 0, length: clientSecret.count)
            )) == 1
    }
}
