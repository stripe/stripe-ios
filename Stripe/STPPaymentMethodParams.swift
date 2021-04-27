//
//  STPPaymentMethodParams.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// An object representing parameters used to create a PaymentMethod object.
/// @note To create a PaymentMethod from an Apple Pay PKPaymentToken, see `STPAPIClient createPaymentMethodWithPayment:completion:`
/// - seealso: https://stripe.com/docs/api/payment_methods/create
public class STPPaymentMethodParams: NSObject, STPFormEncodable, STPPaymentOption {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The type of payment method.  The associated property will contain additional information (e.g. `type == STPPaymentMethodTypeCard` means `card` should also be populated).

    @objc public var type: STPPaymentMethodType {
        get {
            return STPPaymentMethod.type(from: rawTypeString ?? "")
        }
        set(newType) {
            if newType != self.type {
                rawTypeString = STPPaymentMethod.string(from: newType)
            }
        }
    }
    /// The raw underlying type string sent to the server.
    /// Generally you should use `type` instead unless you have a reason not to.
    /// You can use this if you want to create a param of a type not yet supported
    /// by the current version of the SDK's `STPPaymentMethodType` enum.
    /// Setting this to a value not known by the SDK causes `type` to
    /// return `STPPaymentMethodTypeUnknown`
    @objc public var rawTypeString: String?
    /// Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
    @objc public var billingDetails: STPPaymentMethodBillingDetails?
    /// If this is a card PaymentMethod, this contains the user’s card details.
    @objc public var card: STPPaymentMethodCardParams?
    /// If this is an Alipay PaymentMethod, this contains additional details.
    @objc public var alipay: STPPaymentMethodAlipayParams?
    /// If this is a iDEAL PaymentMethod, this contains details about user's bank.
    @objc public var iDEAL: STPPaymentMethodiDEALParams?
    /// If this is a FPX PaymentMethod, this contains details about user's bank.
    @objc public var fpx: STPPaymentMethodFPXParams?
    /// If this is a SEPA Debit PaymentMethod, this contains details about the bank to debit.
    @objc public var sepaDebit: STPPaymentMethodSEPADebitParams?
    /// If this is a Bacs Debit PaymentMethod, this contains details about the bank account to debit.
    @objc public var bacsDebit: STPPaymentMethodBacsDebitParams?
    /// If this is an AU BECS Debit PaymentMethod, this contains details about the bank to debit.
    @objc public var auBECSDebit: STPPaymentMethodAUBECSDebitParams?
    /// If this is a giropay PaymentMethod, this contains additional details.
    @objc public var giropay: STPPaymentMethodGiropayParams?
    /// If this is a PayPal PaymentMethod, this contains additional details. :nodoc:
    @objc public var payPal: STPPaymentMethodPayPalParams?
    /// If this is a Przelewy24 PaymentMethod, this contains additional details.
    @objc public var przelewy24: STPPaymentMethodPrzelewy24Params?
    /// If this is an EPS PaymentMethod, this contains additional details.
    @objc public var eps: STPPaymentMethodEPSParams?
    /// If this is a Bancontact PaymentMethod, this contains additional details.
    @objc public var bancontact: STPPaymentMethodBancontactParams?
    /// If this is a NetBanking PaymentMethod, this contains additional details.
    @objc public var netBanking: STPPaymentMethodNetBankingParams?
    /// If this is an OXXO PaymentMethod, this contains additional details.
    @objc public var oxxo: STPPaymentMethodOXXOParams?
    /// If this is a Sofort PaymentMethod, this contains additional details.
    @objc public var sofort: STPPaymentMethodSofortParams?
    /// If this is a UPI PaymentMethod, this contains additional details.
    @objc public var upi: STPPaymentMethodUPIParams?
    /// If this is a GrabPay PaymentMethod, this contains additional details.
    @objc public var grabPay: STPPaymentMethodGrabPayParams?
    /// If this is a Afterpay PaymentMethod, this contains additional details.
    @objc public var afterpayClearpay: STPPaymentMethodAfterpayClearpayParams?
    /// If this is a BLIK PaymentMethod, this contains additional details.
    @objc public var blik: STPPaymentMethodBLIKParams?

    /// Set of key-value pairs that you can attach to the PaymentMethod. This can be useful for storing additional information about the PaymentMethod in a structured format.
    @objc public var metadata: [String: String]?

    /// Creates params for a card PaymentMethod.
    /// - Parameters:
    ///   - card:                An object containing the user's card details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        card: STPPaymentMethodCardParams, billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .card
        self.card = card
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for an iDEAL PaymentMethod.
    /// - Parameters:
    ///   - iDEAL:               An object containing the user's iDEAL bank details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        iDEAL: STPPaymentMethodiDEALParams, billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .iDEAL
        self.iDEAL = iDEAL
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for an FPX PaymentMethod.
    /// - Parameters:
    ///   - fpx:                 An object containing the user's FPX bank details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        fpx: STPPaymentMethodFPXParams, billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .FPX
        self.fpx = fpx
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for a SEPA Debit PaymentMethod;
    /// - Parameters:
    ///   - sepaDebit:   An object containing the SEPA bank debit details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` is required for SEPA Debit PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        sepaDebit: STPPaymentMethodSEPADebitParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .SEPADebit
        self.sepaDebit = sepaDebit
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for a Bacs Debit PaymentMethod;
    /// - Parameters:
    ///   - bacsDebit:   An object containing the Bacs bank debit details.
    ///   - billingDetails:  An object containing the user's billing details. Note that name, email, and address are required for Bacs Debit PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        bacsDebit: STPPaymentMethodBacsDebitParams, billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .bacsDebit
        self.bacsDebit = bacsDebit
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for an AU BECS Debit PaymentMethod;
    /// - Parameters:
    ///   - auBECSDebit:   An object containing the AU BECS bank debit details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` and `billingDetails.email` are required for AU BECS Debit PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        aubecsDebit auBECSDebit: STPPaymentMethodAUBECSDebitParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .AUBECSDebit
        self.auBECSDebit = auBECSDebit
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for a giropay PaymentMethod;
    /// - Parameters:
    ///   - giropay:   An object containing additional giropay details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` is required for giropay PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        giropay: STPPaymentMethodGiropayParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .giropay
        self.giropay = giropay
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for an EPS PaymentMethod;
    /// - Parameters:
    ///   - eps:   An object containing additional EPS details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` is required for EPS PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        eps: STPPaymentMethodEPSParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .EPS
        self.eps = eps
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for a Przelewy24 PaymentMethod;
    /// - Parameters:
    ///   - przelewy24:   An object containing additional Przelewy24 details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.email` is required for Przelewy24 PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        przelewy24: STPPaymentMethodPrzelewy24Params,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .przelewy24
        self.przelewy24 = przelewy24
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for a Bancontact PaymentMethod;
    /// - Parameters:
    ///   - bancontact:   An object containing additional Bancontact details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` is required for Bancontact PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        bancontact: STPPaymentMethodBancontactParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .bancontact
        self.bancontact = bancontact
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for a NetBanking PaymentMethod;
    /// - Parameters:
    ///   - netBanking:   An object containing additional NetBanking details.
    ///   - billingDetails:  An object containing the user's billing details.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        netBanking: STPPaymentMethodNetBankingParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .netBanking
        self.netBanking = netBanking
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for a GrabPay PaymentMethod;
    /// - Parameters:
    ///   - grabPay:   An object containing additional GrabPay details.
    ///   - billingDetails:  An object containing the user's billing details.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        grabPay: STPPaymentMethodGrabPayParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .grabPay
        self.grabPay = grabPay
        self.billingDetails = billingDetails
    }

    /// Creates params for an OXXO PaymentMethod;
    /// - Parameters:
    ///   - oxxo:   An object containing additional OXXO details.
    ///   - billingDetails:  An object containing the user's billing details.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        oxxo: STPPaymentMethodOXXOParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .OXXO
        self.oxxo = oxxo
        self.billingDetails = billingDetails
    }

    /// Creates params for a Sofort PaymentMethod;
    /// - Parameters:
    ///   - sofort:   An object containing additional Sofort details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` and `billingDetails.email` are required to save bank details from a Sofort payment.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        sofort: STPPaymentMethodSofortParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .sofort
        self.sofort = sofort
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for a UPI PaymentMethod;
    /// - Parameters:
    ///   - upi:   An object containing additional UPI details.
    ///   - billingDetails:  An object containing the user's billing details.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        upi: STPPaymentMethodUPIParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .UPI
        self.upi = upi
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for an Alipay PaymentMethod.
    /// - Parameters:
    ///   - alipay:   An object containing additional Alipay details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        alipay: STPPaymentMethodAlipayParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .alipay
        self.alipay = alipay
        self.billingDetails = billingDetails
    }

    /// Creates params for a PayPal PaymentMethod. :nodoc:
    /// - Parameters:
    ///   - payPal:   An object containing additional PayPal details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        payPal: STPPaymentMethodPayPalParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .payPal
        self.payPal = payPal
        self.billingDetails = billingDetails
    }

    /// Creates params for an AfterpayClearpay PaymentMethod. :nodoc:
    /// - Parameters:
    ///   - afterpayClearpay:   An object containing additional AfterpayClearpay details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        afterpayClearpay: STPPaymentMethodAfterpayClearpayParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .afterpayClearpay
        self.afterpayClearpay = afterpayClearpay
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    /// Creates params for a BLIK PaymentMethod.
    /// - Parameters:
    ///   - blik:                An object containing additional BLIK details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        blik: STPPaymentMethodBLIKParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .blik
        self.blik = blik
        self.billingDetails = billingDetails
        self.metadata = metadata
    }
    /// Creates params from a single-use PaymentMethod. This is useful for recreating a new payment method
    /// with similar settings. It will return nil if used with a reusable PaymentMethod.
    /// - Parameter paymentMethod:       An object containing the original single-use PaymentMethod.
    @objc public convenience init?(singleUsePaymentMethod paymentMethod: STPPaymentMethod) {
        self.init()
        switch paymentMethod.type {
        case .EPS:
            self.type = .EPS
            let eps = STPPaymentMethodEPSParams()
            self.eps = eps
            self.billingDetails = paymentMethod.billingDetails
        case .FPX:
            self.type = .FPX
            let fpx = STPPaymentMethodFPXParams()
            fpx.rawBankString = paymentMethod.fpx?.bankIdentifierCode
            self.fpx = fpx
            self.billingDetails = paymentMethod.billingDetails
        case .iDEAL:
            self.type = .iDEAL
            let iDEAL = STPPaymentMethodiDEALParams()
            self.iDEAL = iDEAL
            self.iDEAL?.bankName = paymentMethod.iDEAL?.bankName
            self.billingDetails = paymentMethod.billingDetails
        case .giropay:
            self.type = .giropay
            let giropay = STPPaymentMethodGiropayParams()
            self.giropay = giropay
            self.billingDetails = paymentMethod.billingDetails
        case .przelewy24:
            self.type = .przelewy24
            let przelewy24 = STPPaymentMethodPrzelewy24Params()
            self.przelewy24 = przelewy24
            self.billingDetails = paymentMethod.billingDetails
        case .bancontact:
            self.type = .bancontact
            let bancontact = STPPaymentMethodBancontactParams()
            self.bancontact = bancontact
            self.billingDetails = paymentMethod.billingDetails
        case .netBanking:
            self.type = .netBanking
            let netBanking = STPPaymentMethodNetBankingParams()
            self.netBanking = netBanking
            self.billingDetails = paymentMethod.billingDetails
        case .OXXO:
            self.type = .OXXO
            let oxxo = STPPaymentMethodOXXOParams()
            self.oxxo = oxxo
            self.billingDetails = paymentMethod.billingDetails
        case .alipay:
            // Careful! In the future, when we add recurring Alipay, we'll need to look at this!
            self.type = .alipay
            self.billingDetails = paymentMethod.billingDetails
        case .sofort:
            self.type = .sofort
            let sofort = STPPaymentMethodSofortParams()
            self.sofort = sofort
            self.billingDetails = paymentMethod.billingDetails
        case .UPI:
            self.type = .UPI
            let upi = STPPaymentMethodUPIParams()
            self.upi = upi
            self.billingDetails = paymentMethod.billingDetails
        case .grabPay:
            self.type = .grabPay
            let grabpay = STPPaymentMethodGrabPayParams()
            self.grabPay = grabpay
            self.billingDetails = paymentMethod.billingDetails
        case .afterpayClearpay:
            self.type = .afterpayClearpay
            self.afterpayClearpay = STPPaymentMethodAfterpayClearpayParams()
            self.billingDetails = paymentMethod.billingDetails
        // All reusable PaymentMethods go below:
        case .SEPADebit, .bacsDebit, .card, .cardPresent, .AUBECSDebit,  // fall through
            .unknown:
            return nil
        default:
            break
        }
    }

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return nil
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter:rawTypeString)): "type",
            NSStringFromSelector(#selector(getter:billingDetails)): "billing_details",
            NSStringFromSelector(#selector(getter:card)): "card",
            NSStringFromSelector(#selector(getter:iDEAL)): "ideal",
            NSStringFromSelector(#selector(getter:eps)): "eps",
            NSStringFromSelector(#selector(getter:fpx)): "fpx",
            NSStringFromSelector(#selector(getter:sepaDebit)): "sepa_debit",
            NSStringFromSelector(#selector(getter:bacsDebit)): "bacs_debit",
            NSStringFromSelector(#selector(getter:auBECSDebit)): "au_becs_debit",
            NSStringFromSelector(#selector(getter:giropay)): "giropay",
            NSStringFromSelector(#selector(getter:grabPay)): "grabpay",
            NSStringFromSelector(#selector(getter:przelewy24)): "p24",
            NSStringFromSelector(#selector(getter:bancontact)): "bancontact",
            NSStringFromSelector(#selector(getter:netBanking)): "netbanking",
            NSStringFromSelector(#selector(getter:oxxo)): "oxxo",
            NSStringFromSelector(#selector(getter:sofort)): "sofort",
            NSStringFromSelector(#selector(getter:upi)): "upi",
            NSStringFromSelector(#selector(getter:afterpayClearpay)): "afterpayClearpay",
            NSStringFromSelector(#selector(getter:metadata)): "metadata",
        ]
    }

    // MARK: - STPPaymentOption
    @objc public var image: UIImage {
        if type == .card && card != nil {
            let brand = STPCardValidator.brand(forNumber: card?.number ?? "")
            return STPImageLibrary.cardBrandImage(for: brand)
        } else {
            return STPImageLibrary.cardBrandImage(for: .unknown)
        }
    }

    @objc public var templateImage: UIImage {
        if type == .card && card != nil {
            let brand = STPCardValidator.brand(forNumber: card?.number ?? "")
            return STPImageLibrary.templatedBrandImage(for: brand)
        } else if type == .FPX {
            return STPImageLibrary.bankIcon()
        } else {
            return STPImageLibrary.templatedBrandImage(for: .unknown)
        }
    }

    @objc public var label: String {
        switch type {
        case .alipay:
            return "Alipay"  //? Why aren't these localized?
        case .card:
            if let card = card {
                let brand = STPCardValidator.brand(forNumber: card.number ?? "")
                let brandString = STPCardBrandUtilities.stringFrom(brand)
                return "\(brandString ?? "") \(card.last4 ?? "")"
            } else {
                return STPCardBrandUtilities.stringFrom(.unknown) ?? ""
            }
        case .iDEAL:
            return "iDEAL"
        case .FPX:
            if let fpx = fpx {
                return STPFPXBank.stringFrom(fpx.bank) ?? ""
            } else {
                return "FPX"
            }
        case .SEPADebit:
            return "SEPA Debit"
        case .bacsDebit:
            return "Bacs Debit"
        case .AUBECSDebit:
            return "AU BECS Debit"
        case .giropay:
            return "giropay"
        case .przelewy24:
            return "Przelewy24"
        case .EPS:
            return "EPS"
        case .bancontact:
            return "Bancontact"
        case .netBanking:
            return "NetBanking"
        case .OXXO:
            return "OXXO"
        case .sofort:
            return "Sofort"
        case .UPI:
            return "UPI"
        case .grabPay:
            return "GrabPay"
        case .payPal:
            return "PayPal"
        case .afterpayClearpay:
            return "Afterpay Clearpay"
        case .blik:
            return "BLIK"
        case .cardPresent, .unknown:
            return STPLocalizedString("Unknown", "Default missing source type label")
        @unknown default:
            return STPLocalizedString("Unknown", "Default missing source type label")
        }
    }

    @objc public var isReusable: Bool {
        switch type {
        case .card:
            return true
        case .alipay, .AUBECSDebit, .bacsDebit, .SEPADebit, .iDEAL, .FPX, .cardPresent, .giropay,
            .grabPay, .EPS, .przelewy24, .bancontact, .netBanking, .OXXO, .payPal, .sofort, .UPI,
            .afterpayClearpay, .blik, // fall through
            .unknown:
            return false
        @unknown default:
            return false
        }
    }
}

// MARK: - Legacy ObjC

@objc
extension STPPaymentMethodParams {
    /// Creates params for a card PaymentMethod.
    /// - Parameters:
    ///   - card:                An object containing the user's card details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc(paramsWithCard:billingDetails:metadata:)
    public class func paramsWith(
        card: STPPaymentMethodCardParams, billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            card: card, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for an iDEAL PaymentMethod.
    /// - Parameters:
    ///   - iDEAL:               An object containing the user's iDEAL bank details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc(paramsWithiDEAL:billingDetails:metadata:)
    public class func paramsWith(
        iDEAL: STPPaymentMethodiDEALParams, billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            iDEAL: iDEAL, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for an FPX PaymentMethod.
    /// - Parameters:
    ///   - fpx:                 An object containing the user's FPX bank details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc(paramsWithFPX:billingDetails:metadata:)
    public class func paramsWith(
        fpx: STPPaymentMethodFPXParams, billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(fpx: fpx, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for a SEPA Debit PaymentMethod;
    /// - Parameters:
    ///   - sepaDebit:   An object containing the SEPA bank debit details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` is required for SEPA Debit PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc(paramsWithSEPADebit:billingDetails:metadata:)
    public class func paramsWith(
        sepaDebit: STPPaymentMethodSEPADebitParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            sepaDebit: sepaDebit, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for a Bacs Debit PaymentMethod;
    /// - Parameters:
    ///   - bacsDebit:   An object containing the Bacs bank debit details.
    ///   - billingDetails:  An object containing the user's billing details. Note that name, email, and address are required for Bacs Debit PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc(paramsWithBacsDebit:billingDetails:metadata:)
    public class func paramsWith(
        bacsDebit: STPPaymentMethodBacsDebitParams, billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            bacsDebit: bacsDebit, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for an AU BECS Debit PaymentMethod;
    /// - Parameters:
    ///   - auBECSDebit:   An object containing the AU BECS bank debit details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` and `billingDetails.email` are required for AU BECS Debit PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc(paramsWithAUBECSDebit:billingDetails:metadata:)
    public class func paramsWith(
        auBECSDebit: STPPaymentMethodAUBECSDebitParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            aubecsDebit: auBECSDebit, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for a giropay PaymentMethod;
    /// - Parameters:
    ///   - giropay:   An object containing additional giropay details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` is required for giropay PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc(paramsWithGiropay:billingDetails:metadata:)
    public class func paramsWith(
        giropay: STPPaymentMethodGiropayParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            giropay: giropay, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for an EPS PaymentMethod;
    /// - Parameters:
    ///   - eps:   An object containing additional EPS details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` is required for EPS PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc(paramsWithEPS:billingDetails:metadata:)
    public class func paramsWith(
        eps: STPPaymentMethodEPSParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(eps: eps, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for a Przelewy24 PaymentMethod;
    /// - Parameters:
    ///   - przelewy24:   An object containing additional Przelewy24 details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.email` is required for Przelewy24 PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc(paramsWithPrzelewy24:billingDetails:metadata:)
    public class func paramsWith(
        przelewy24: STPPaymentMethodPrzelewy24Params,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            przelewy24: przelewy24, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for a Bancontact PaymentMethod;
    /// - Parameters:
    ///   - bancontact:   An object containing additional Bancontact details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` is required for Bancontact PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc(paramsWithBancontact:billingDetails:metadata:)
    public class func paramsWith(
        bancontact: STPPaymentMethodBancontactParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            bancontact: bancontact, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for a NetBanking PaymentMethod;
    /// - Parameters:
    ///   - netBanking:   An object containing additional NetBanking details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` is required for Bancontact PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc(paramsWithNetBanking:billingDetails:metadata:)
    public class func paramsWith(
        netBanking: STPPaymentMethodNetBankingParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            netBanking: netBanking, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for an OXXO PaymentMethod;
    /// - Parameters:
    ///   - oxxo:   An object containing additional OXXO details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` is required for OXXO PaymentMethods.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc(paramsWithOXXO:billingDetails:metadata:)
    public class func paramsWith(
        oxxo: STPPaymentMethodOXXOParams,
        billingDetails: STPPaymentMethodBillingDetails,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            oxxo: oxxo, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for a GrabPay PaymentMethod;
    /// - Parameters:
    ///   - grabPay:   An object containing additional GrabPay details.
    ///   - billingDetails:  An object containing the user's billing details.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc(paramsWithGrabPay:billingDetails:metadata:)
    public class func paramsWith(
        grabPay: STPPaymentMethodGrabPayParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            grabPay: grabPay, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for a Sofort PaymentMethod;
    /// - Parameters:
    ///   - sofort:   An object containing additional Sofort details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` and `billingDetails.email` are required to save bank details from a Sofort payment.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc(paramsWithSofort:billingDetails:metadata:)
    public class func paramsWith(
        sofort: STPPaymentMethodSofortParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            sofort: sofort, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for a UPI PaymentMethod;
    /// - Parameters:
    ///   - upi:   An object containing additional UPI details.
    ///   - billingDetails:  An object containing the user's billing details. Note that `billingDetails.name` and `billingDetails.email` are required to save bank details from a UPI payment.
    ///   - metadata:     Additional information to attach to the PaymentMethod.
    @objc(paramsWithUPI:billingDetails:metadata:)
    public class func paramsWith(
        upi: STPPaymentMethodUPIParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            upi: upi, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for an Alipay PaymentMethod.
    /// - Parameters:
    ///   - alipay:   An object containing additional Alipay details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc(paramsWithAlipay:billingDetails:metadata:)
    public class func paramsWith(
        alipay: STPPaymentMethodAlipayParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            alipay: alipay, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for a PayPal PaymentMethod.
    /// - Parameters:
    ///   - payPal:   An object containing additional PayPal details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc(paramsWithPayPal:billingDetails:metadata:)
    public class func paramsWith(
        payPal: STPPaymentMethodPayPalParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            payPal: payPal, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for an AfterpayClearpay PaymentMethod.
    /// - Parameters:
    ///   - afterpayClearpay:   An object containing additional AfterpayClearpay details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc(paramsWithAfterpayClearpay:billingDetails:metadata:)
    public class func paramsWith(
        afterpayClearpay: STPPaymentMethodAfterpayClearpayParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            afterpayClearpay: afterpayClearpay, billingDetails: billingDetails, metadata: metadata)
    }

    /// Creates params for a BLIK PaymentMethod.
    /// - Parameters:
    ///   - blik:           An object containing additional BLIK details.
    ///   - billingDetails: An object containing the user's billing details.
    ///   - metadata:       Additional information to attach to the PaymentMethod.
    @objc(paramsWithBLIK:billingDetails:metadata:)
    public class func paramsWith(
        blik: STPPaymentMethodBLIKParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            blik: blik, billingDetails: billingDetails, metadata: metadata)
    }
}

extension STPPaymentMethodParams {
    var paymentSheetLabel: String {
        switch type {
        case .card:
            return "••••\(card?.last4 ?? "")"
        default:
            return label
        }
    }
}
