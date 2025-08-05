//
//  PaymentMethodParams.swift
//  StripeApplePay
//
//  Created by David Estes on 6/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension StripeAPI {
    /// An object representing parameters used to create a PaymentMethod object.
    /// - seealso: https://stripe.com/docs/api/payment_methods/create
    @_spi(STP) public struct PaymentMethodParams: UnknownFieldsEncodable {
        /// The type of payment method.
        /// The associated property will contain additional information (e.g. `type == .card` means `card` should also be populated).
        @_spi(STP) public var type: PaymentMethod.PaymentMethodType

        /// If this is a card PaymentMethod, this contains the user’s card details.
        @_spi(STP) public var card: Card?

        /// Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
        @_spi(STP) public var billingDetails: BillingDetails?

        /// Used internally to identify the version of the SDK sending the request
        @_spi(STP) public var paymentUserAgent: String? = {
            return PaymentsSDKVariant.paymentUserAgent
        }()

        /// Radar options that may contain HCaptcha token
        @_spi(STP) var radarOptions: RadarOptions?

        /// Contains metadata with identifiers for the session and information about the integration
        @_spi(STP) public var clientAttributionMetadata: ClientAttributionMetadata = ClientAttributionMetadata()

        /// :nodoc:
        @_spi(STP) public struct Card: UnknownFieldsEncodable {
            /// The card number, as a string without any separators. Ex. "4242424242424242"
            @_spi(STP) public var number: String?
            /// Number representing the card's expiration month. Ex. 1
            @_spi(STP) public var expMonth: Int?
            /// Two- or four-digit number representing the card's expiration year.
            @_spi(STP) public var expYear: Int?
            /// For backwards compatibility, you can alternatively set this as a Stripe token (e.g., for Apple Pay)
            @_spi(STP) public var token: String?
            /// Card security code. It is highly recommended to always include this value.
            @_spi(STP) public var cvc: String?

            /// The last 4 digits of the card's number, if it's been set, otherwise nil.
            @_spi(STP) public var last4: String? {
                if number != nil && (number?.count ?? 0) >= 4 {
                    return (number as NSString?)?.substring(from: (number?.count ?? 0) - 4)
                } else {
                    return nil
                }
            }
            @_spi(STP) public var _additionalParametersStorage: NonEncodableParameters?
        }

        /// :nodoc:
        @_spi(STP) public struct RadarOptions: UnknownFieldsEncodable {
            @_spi(STP) public var hcaptchaToken: String?
            @_spi(STP) public var _additionalParametersStorage: NonEncodableParameters?
        }

        // See https://docs.google.com/document/d/11wWdHwWzTJGe_29mHsk71fk-kG4lwvp8TLBBf4ws9JM/edit?usp=sharing
        @_spi(STP) public struct ClientAttributionMetadata: UnknownFieldsEncodable {

            public enum IntentCreationFlow: String {
                case standard
                case deferred
            }

            public enum PaymentMethodSelectionFlow: String {
                case automatic
                case merchantSpecified = "merchant_specified"
            }

            /// The identifier string for the session
            let clientSessionId: String?
            /// The identifier string for the elements session
            var elementsSessionConfigId: String?
            /// The source for the merchant integration
            let merchantIntegrationSource: String
            /// The subtype for the merchant integration
            let merchantIntegrationSubtype: String
            /// The version for the merchant integration
            let merchantIntegrationVersion: String
            /// The intent creation flow for the merchant integration. Can be `standard` or `deferred`
            var paymentIntentCreationFlow: String?
            /// The payment method selection for the merchant integration. Can be `automatic` or `merchant_specified`
            var paymentMethodSelectionFlow: String?

            public init(elementsSessionConfigId: String? = nil,
                        paymentIntentCreationFlow: IntentCreationFlow? = nil,
                        paymentMethodSelectionFlow: PaymentMethodSelectionFlow? = nil) {
                self.clientSessionId = AnalyticsHelper.shared.sessionID
                self.elementsSessionConfigId = elementsSessionConfigId
                self.merchantIntegrationSource = "elements"
                self.merchantIntegrationSubtype = "mobile"
                self.merchantIntegrationVersion = "stripe-ios/\(StripeAPIConfiguration.STPSDKVersion)"
                self.paymentIntentCreationFlow = paymentIntentCreationFlow?.rawValue
                self.paymentMethodSelectionFlow = paymentMethodSelectionFlow?.rawValue
            }

            @_spi(STP) public var _additionalParametersStorage: NonEncodableParameters?
        }

        @_spi(STP) public var _additionalParametersStorage: NonEncodableParameters?
    }
}

extension StripeAPI.PaymentMethodParams.Card: CustomStringConvertible, CustomDebugStringConvertible,
    CustomLeafReflectable
{
    @_spi(STP) public var debugDescription: String {
        return description
    }

    @_spi(STP) public var description: String {
        return "Card \(last4 ?? "")"
    }

    @_spi(STP) public var customMirror: Mirror {
        return Mirror(reflecting: self.description)
    }
}

// MARK: - Passive HCaptcha
extension StripeAPI.PaymentMethodParams {
    @_spi(STP) public func startPassiveCaptcha(siteKey: String?, rqdata: String?, completion: ((String?) -> Void)? = nil) {
        guard let siteKey,
              let hcaptcha = try? HCaptcha(apiKey: siteKey, passiveApiKey: true, baseURL: URL(string: "http://localhost"), rqdata: rqdata) else {
            completion?(nil)
            return
        }
        hcaptcha.didFinishLoading {
            hcaptcha.validate { result in
                let hcaptchaToken = try? result.dematerialize()
                completion?(hcaptchaToken)
            }
        }
    }
}
