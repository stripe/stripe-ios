//
//  STPSourceEnums.swift
//  StripePayments
//
//  Created by Brian Dorfman on 8/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// Authentication flows for a Source
@objc public enum STPSourceFlow: Int {
    /// No action is required from your customer.
    /// @note WeChat Pay Sources also have this flow type.
    case none
    /// Your customer must be redirected to their online banking service (either a website or mobile banking app) to approve the payment.
    case redirect
    /// Your customer must verify ownership of their account by providing a code that you post to the Stripe API for authentication.
    case codeVerification
    /// Your customer must push funds to the account information provided.
    case receiver
    /// The source's flow is unknown.
    case unknown
}

/// Usage types for a Source
@objc public enum STPSourceUsage: Int {
    /// The source can be reused.
    case reusable
    /// The source can only be used once.
    case singleUse
    /// The source's usage is unknown.
    case unknown
}

/// Status types for a Source
@objc public enum STPSourceStatus: Int {
    /// The source has been created and is awaiting customer action.
    case pending
    /// The source is ready to use. The customer action has been completed or the
    /// payment method requires no customer action.
    case chargeable
    /// The source has been used. This status only applies to single-use sources.
    case consumed
    /// The source, which was chargeable, has expired because it was not used to
    /// make a charge request within a specified amount of time.
    case canceled
    /// Your customer has not taken the required action or revoked your access
    /// (e.g., did not authorize the payment with their bank or canceled their
    /// mandate acceptance for SEPA direct debits).
    case failed
    /// The source status is unknown.
    case unknown
}

/// Types for a Source
/// - seealso: https://stripe.com/docs/sources
@objc public enum STPSourceType: Int {
    /// A Bancontact source. - seealso: https://stripe.com/docs/sources/bancontact
    case bancontact
    /// A card source. - seealso: https://stripe.com/docs/sources/cards
    case card
    /// A Giropay source. - seealso: https://stripe.com/docs/sources/giropay
    case giropay
    /// An iDEAL source. - seealso: https://stripe.com/docs/sources/ideal
    @objc(STPSourceTypeiDEAL) case iDEAL
    /// A SEPA Direct Debit source. - seealso: https://stripe.com/docs/sources/sepa-debit
    case SEPADebit
    /// A Sofort source. - seealso: https://stripe.com/docs/sources/sofort
    case sofort
    /// A 3DS card source. - seealso: https://stripe.com/docs/sources/three-d-secure
    case threeDSecure
    /// An Alipay source. - seealso: https://stripe.com/docs/sources/alipay
    case alipay
    /// A P24 source. - seealso: https://stripe.com/docs/sources/p24
    case P24
    /// An EPS source. - seealso: https://stripe.com/docs/sources/eps
    case EPS
    /// A Multibanco source. - seealso: https://stripe.com/docs/sources/multibanco
    case multibanco
    /// A WeChat Pay source. - seealso: https://stripe.com/docs/sources/wechat-pay
    case weChatPay
    /// A Klarna source. - seealso: https://stripe.com/docs/sources/klarna
    case klarna
    /// An unknown type of source.
    case unknown
}

/// Custom payment methods for Klarna
/// - seealso: https://stripe.com/docs/sources/klarna#create-source
@objc public enum STPKlarnaPaymentMethods: Int {
    /// Don't specify any custom payment methods.
    case none
    /// Offer payments over 4 installments. (a.k.a. Pay Later in 4)
    case payIn4
    /// Offer payments over an arbitrary number of installments. (a.k.a. Slice It)
    case installments
    /// Offer payments over 4 or an arbitrary number of installments.
    case payIn4OrInstallments
}
