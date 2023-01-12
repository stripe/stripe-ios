//
//  IntegrationMethods.swift
//  IntegrationTester
//
//  Created by David Estes on 2/12/21.
//

import Foundation
import Stripe

public enum IntegrationMethod: String, CaseIterable {
    case card = "Card"
    case cardSetupIntents = "Card (SetupIntents)"
    case applePay = "Apple Pay"
    case sofort = "Sofort"
    case fpx = "FPX"
    case sepaDebit = "SEPA Debit"
    case iDEAL
    case alipay = "Alipay"
    case bacsDebit = "Bacs Debit"
    case aubecsDebit = "AU BECS Debit"
    case giropay
    case przelewy24 = "Przelewy24"
    case bancontact = "Bancontact"
    case eps = "EPS"
    case grabpay = "GrabPay"
    case oxxo = "OXXO"
    case afterpay = "Afterpay Clearpay"
    case weChatPay = "WeChat Pay"
}

// MARK: IntegrationMethod PaymentMethod/Sources Params
extension IntegrationMethod {
  public var defaultPaymentMethodParams: STPPaymentMethodParams {
      switch self {
      case .fpx:
          let fpx = STPPaymentMethodFPXParams()
          fpx.bank = .HSBC
          return STPPaymentMethodParams(fpx: fpx, billingDetails: nil, metadata: nil)
      case .iDEAL:
          let ideal = STPPaymentMethodiDEALParams()
          return STPPaymentMethodParams(iDEAL: ideal, billingDetails: nil, metadata: nil)
      case .sofort:
          let sofort = STPPaymentMethodSofortParams()
          sofort.country = "NL"
          return STPPaymentMethodParams(sofort: sofort, billingDetails: nil, metadata: nil)
      case .sepaDebit:
          let sepaDebit = STPPaymentMethodSEPADebitParams()
          return STPPaymentMethodParams(sepaDebit: sepaDebit, billingDetails: Self.defaultBillingDetails, metadata: nil)
      case .alipay:
          let alipay = STPPaymentMethodAlipayParams()
          return STPPaymentMethodParams(alipay: alipay, billingDetails: nil, metadata: nil)
      case .bacsDebit:
          // You must provide UI to collect the following hard-coded customer information. Bacs in
          // the UK has strict requirements around customer-facing mandate collection forms. Stripe
          // needs to approve any forms for collecting mandates. Contact bacs-debits@stripe.com with
          // any questions.
          let bacsDebit = STPPaymentMethodBacsDebitParams()
          bacsDebit.sortCode = "108800"
          bacsDebit.accountNumber = "00012345"
          return STPPaymentMethodParams(bacsDebit: bacsDebit, billingDetails: Self.defaultBillingDetails, metadata: nil)
      case .aubecsDebit:
          let aubecsDebit = STPPaymentMethodAUBECSDebitParams()
          return STPPaymentMethodParams(aubecsDebit: aubecsDebit, billingDetails: Self.defaultBillingDetails, metadata: nil)
      case .giropay:
          let giropay = STPPaymentMethodGiropayParams()
          return STPPaymentMethodParams(giropay: giropay, billingDetails: Self.defaultBillingDetails, metadata: nil)
      case .przelewy24:
          let przelewy24 = STPPaymentMethodPrzelewy24Params()
          return STPPaymentMethodParams(przelewy24: przelewy24, billingDetails: Self.defaultBillingDetails, metadata: nil)
      case .bancontact:
          let bancontact = STPPaymentMethodBancontactParams()
          return STPPaymentMethodParams(bancontact: bancontact, billingDetails: Self.defaultBillingDetails, metadata: nil)
      case .eps:
          let eps = STPPaymentMethodEPSParams()
          return STPPaymentMethodParams(eps: eps, billingDetails: Self.defaultBillingDetails, metadata: nil)
      case .grabpay:
          let grabpay = STPPaymentMethodGrabPayParams()
          return STPPaymentMethodParams(grabPay: grabpay, billingDetails: nil, metadata: nil)
      case .oxxo:
          let oxxo = STPPaymentMethodOXXOParams()
          return STPPaymentMethodParams(oxxo: oxxo, billingDetails: nil, metadata: nil)
      case .afterpay:
          let afterpay = STPPaymentMethodAfterpayClearpayParams()
          return STPPaymentMethodParams(afterpayClearpay: afterpay, billingDetails: nil, metadata: nil)
      case .card,
           .cardSetupIntents:
          let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expYear = NSNumber(value: Calendar.current.dateComponents([.year], from: Date()).year! % 100 + 2)
        cardParams.expMonth = 12
        cardParams.cvc = "123"
          return STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
      case .weChatPay:
//            return STPPaymentMethodParams(weChatPay: STPPaymentMethodWeChatPayParams(), billingDetails: nil, metadata: nil)
        assertionFailure("WeChat Pay is currently unavailable")
        return STPPaymentMethodParams()
      case .applePay:
          assertionFailure("Not supported by PaymentMethods")
          return STPPaymentMethodParams()
      }
  }

    public var defaultPaymentMethodOptions: STPConfirmPaymentMethodOptions? {
        switch self {
        case .weChatPay:
          let pmOptions = STPConfirmPaymentMethodOptions()
            pmOptions.weChatPayOptions = STPConfirmWeChatPayOptions(appId: "wx65997d6307c3827d")
            return pmOptions
        default:
            return nil
        }
    }

    public static var defaultBillingDetails: STPPaymentMethodBillingDetails {
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Test Test"
        billingDetails.email = "test@example.com"
        let address = STPPaymentMethodAddress()
        address.line1 = "Threadneedle St"
        address.city = "London"
        address.postalCode = "EC2R 8AH"
        address.country = "GB"
        billingDetails.address = address
        return billingDetails
    }
}
