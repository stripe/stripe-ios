//
//  STPIntentAction.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

//
//  STPIntentNextAction.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Types of next actions for `STPPaymentIntent` and `STPSetupIntent`.
/// You shouldn't need to inspect this yourself; `STPPaymentHandler` will handle any next actions for you.
@objc public enum STPIntentActionType: Int {

    /// This is an unknown action that's been added since the SDK
    /// was last updated.
    /// Update your SDK, or use the `nextAction.allResponseFields`
    /// for custom handling.
    case unknown

    /// The payment intent needs to be authorized by the user. We provide
    /// `STPPaymentHandler` to handle the url redirections necessary.
    case redirectToURL

    /// The payment intent requires additional action handled by `STPPaymentHandler`.
    case useStripeSDK

    /// The action type is OXXO payment. We provide `STPPaymentHandler` to display
    /// the OXXO voucher.
    case OXXODisplayDetails

    /// Contains instructions for authenticating a payment by redirecting your customer to Alipay App or website.
    case alipayHandleRedirect

    /// The action type for BLIK payment methods. The customer must authorize the transaction in their banking app within 1 minute.
    case BLIKAuthorize

    /// Contains instructions for authenticating a payment by redirecting your customer to the WeChat Pay App.
    case weChatPayRedirectToApp

    /// The action type is Boleto payment. We provide `STPPaymentHandler` to display the Boleto voucher.
    case boletoDisplayDetails

    /// Contains details describing the microdeposits verification flow for US Bank Account payments
    case verifyWithMicrodeposits

    /// The action type for UPI payment methods. The customer must complete the transaction in their banking app within 5 minutes.
    case upiAwaitNotification

    /// Contains instructions for authenticating a payment by redirecting your customer to Cash App.
    case cashAppRedirectToApp

    /// Contains details for displaying the QR code required for PayNow.
    case payNowDisplayQrCode

    /// Contains instructions for completing Konbini payments.
    case konbiniDisplayDetails

    /// Contains details for displaying the QR code required for PromptPay.
    case promptpayDisplayQrCode

    /// Contains details for redirecting to the Swish app.
    case swishHandleRedirect

    /// The action type is Multibanco payment. We provide `STPPaymentHandler` to display the Multibanco voucher.
    case multibancoDisplayDetails

    /// Parse the string and return the correct `STPIntentActionType`,
    /// or `STPIntentActionTypeUnknown` if it's unrecognized by this version of the SDK.
    /// - Parameter string: the NSString with the `next_action.type`
    internal init(
        string: String
    ) {
        switch string.lowercased() {
        case "redirect_to_url":
            self = .redirectToURL
        case "use_stripe_sdk":
            self = .useStripeSDK
        case "oxxo_display_details":
            self = .OXXODisplayDetails
        case "alipay_handle_redirect":
            self = .alipayHandleRedirect
        case "wechat_pay_redirect_to_ios_app":
            self = .weChatPayRedirectToApp
        case "boleto_display_details":
            self = .boletoDisplayDetails
        case "blik_authorize":
            self = .BLIKAuthorize
        case "verify_with_microdeposits":
            self = .verifyWithMicrodeposits
        case "upi_await_notification":
            self = .upiAwaitNotification
        case "cashapp_handle_redirect_or_display_qr_code":
            self = .cashAppRedirectToApp
        case "paynow_display_qr_code":
            self = .payNowDisplayQrCode
        case "konbini_display_details":
            self = .konbiniDisplayDetails
        case "promptpay_display_qr_code":
            self = .promptpayDisplayQrCode
        case "swish_handle_redirect_or_display_qr_code":
            self = .swishHandleRedirect
        case "multibanco_display_details":
            self = .multibancoDisplayDetails
        default:
            self = .unknown
        }
    }

    /// Return the string representing the provided `STPIntentActionType`.
    /// - Parameter actionType: the enum value to convert to a string
    /// - Returns: the string, or @"unknown" if this was an unrecognized type
    internal var stringValue: String {
        switch self {
        case .redirectToURL:
            return "redirect_to_url"
        case .useStripeSDK:
            return "use_stripe_sdk"
        case .OXXODisplayDetails:
            return "oxxo_display_details"
        case .alipayHandleRedirect:
            return "alipay_handle_redirect"
        case .BLIKAuthorize:
            return "blik_authorize"
        case .weChatPayRedirectToApp:
            return "wechat_pay_redirect_to_ios_app"
        case .boletoDisplayDetails:
            return "boleto_display_details"
        case .verifyWithMicrodeposits:
            return "verify_with_microdeposits"
        case .upiAwaitNotification:
            return "upi_await_notification"
        case .cashAppRedirectToApp:
            return "cashapp_handle_redirect_or_display_qr_code"
        case .konbiniDisplayDetails:
            return "konbini_display_details"
        case .payNowDisplayQrCode:
            return "paynow_display_qr_code"
        case .promptpayDisplayQrCode:
            return "promptpay_display_qr_code"
        case .swishHandleRedirect:
            return "swish_handle_redirect_or_display_qr_code"
        case .multibancoDisplayDetails:
            return "multibanco_display_details"
        case .unknown:
            break
        }

        // catch any unknown values here
        return "unknown"
    }
}

/// Next action details for `STPPaymentIntent` and `STPSetupIntent`.
/// This is a container for the various types that are available.
/// Check the `type` to see which one it is, and then use the related
/// property for the details necessary to handle it.
/// You cannot directly instantiate an `STPIntentAction`.
public class STPIntentAction: NSObject {

    /// The type of action needed. The value of this field determines which
    /// property of this object contains further details about the action.
    @objc public let type: STPIntentActionType

    /// The details for authorizing via URL, when `type == .redirectToURL`
    @objc public let redirectToURL: STPIntentActionRedirectToURL?

    /// The details for displaying OXXO voucher via URL, when `type == .OXXODisplayDetails`
    @objc public let oxxoDisplayDetails: STPIntentActionOXXODisplayDetails?

    /// Contains instructions for authenticating a payment by redirecting your customer to Alipay App or website.
    @objc public let alipayHandleRedirect: STPIntentActionAlipayHandleRedirect?

    /// Contains instructions for authenticating a payment by redirecting your customer to the WeChat Pay app.
    @objc public let weChatPayRedirectToApp: STPIntentActionWechatPayRedirectToApp?

    /// The details for displaying Boleto voucher via URL, when `type == .boleto`
    @objc public let boletoDisplayDetails: STPIntentActionBoletoDisplayDetails?

    /// Contains details describing microdeposits verification flow for US bank accounts
    @objc public let verifyWithMicrodeposits: STPIntentActionVerifyWithMicrodeposits?

    /// Contains instructions for authenticating a payment by redirecting your customer to Cash App.
    @objc public let cashAppRedirectToApp: STPIntentActionCashAppRedirectToApp?

    /// Contains details for displaying the QR code required for PayNow.
    @objc public let payNowDisplayQrCode: STPIntentActionPayNowDisplayQrCode?

    /// Contains instructions for authenticating a Konbini payment.
    @objc public let konbiniDisplayDetails: STPIntentActionKonbiniDisplayDetails?

    /// Contains details for displaying the QR code required for PromptPay.
    @objc public let promptPayDisplayQrCode: STPIntentActionPromptPayDisplayQrCode?

    /// Contains details for redirecting to the Swish app.
    @objc public let swishHandleRedirect: STPIntentActionSwishHandleRedirect?

    /// The details for displaying Multibanco voucher via URL, when `type == .multibanco`
    @objc public let multibancoDisplayDetails: STPIntentActionMultibancoDisplayDetails?

    internal let useStripeSDK: STPIntentActionUseStripeSDK?

    /// :nodoc:
    @objc public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        var props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPIntentAction.self), self),
            // Type
            "type = \(type.stringValue)",
        ]

        // omit properties that don't apply to this type
        switch type {
        case .redirectToURL:
            if let redirectToURL = redirectToURL {
                props.append("redirectToURL = \(redirectToURL)")
            }
        case .useStripeSDK:
            if let useStripeSDK = useStripeSDK {
                props.append("useStripeSDK = \(useStripeSDK)")
            }
        case .OXXODisplayDetails:
            if let oxxoDisplayDetails = oxxoDisplayDetails {
                props.append("oxxoDisplayDetails = \(oxxoDisplayDetails)")
            }
        case .alipayHandleRedirect:
            if let alipayHandleRedirect = alipayHandleRedirect {
                props.append("alipayHandleRedirect = \(alipayHandleRedirect)")
            }
        case .weChatPayRedirectToApp:
            if let weChatPayRedirectToApp = weChatPayRedirectToApp {
                props.append("weChatPayRedirectToApp = \(weChatPayRedirectToApp)")
            }
        case .boletoDisplayDetails:
            if let boletoDisplayDetails = boletoDisplayDetails {
                props.append("boletoDisplayDetails = \(boletoDisplayDetails)")
            }
        case .BLIKAuthorize:
            break  // no additional details
        case .verifyWithMicrodeposits:
            if let verifyWithMicrodeposits = verifyWithMicrodeposits {
                props.append("verifyWithMicrodeposits = \(verifyWithMicrodeposits)")
            }
        case .upiAwaitNotification:
            props.append("upiAwaitNotification != nil")
        case .cashAppRedirectToApp:
            if let cashAppRedirectToApp = cashAppRedirectToApp {
                props.append("cashAppRedirectToApp = \(cashAppRedirectToApp)")
            }
        case .payNowDisplayQrCode:
            if let payNowDisplayQrCode = payNowDisplayQrCode {
                props.append("payNowDisplayQrCode = \(payNowDisplayQrCode)")
            }
        case .konbiniDisplayDetails:
            if let konbiniDisplayDetails {
                props.append("konbini_display_details = \(konbiniDisplayDetails)")
            }
        case .promptpayDisplayQrCode:
            if let promptPayDisplayQrCode = promptPayDisplayQrCode {
                props.append("promptpayDisplayQrCode = \(promptPayDisplayQrCode)")
            }
        case .swishHandleRedirect:
            if let swishHandleRedirect = swishHandleRedirect {
                props.append("swishHandleRedirect = \(swishHandleRedirect)")
            }
        case .multibancoDisplayDetails:
            if let multibancoDisplayDetails {
                props.append("multibancoDisplayDetails = \(multibancoDisplayDetails)")
            }
        case .unknown:
            // unrecognized type, just show the original dictionary for debugging help
            props.append("allResponseFields = \(allResponseFields)")
        }

        return "<\(props.joined(separator: "; "))>"
    }

    internal init(
        type: STPIntentActionType,
        redirectToURL: STPIntentActionRedirectToURL?,
        alipayHandleRedirect: STPIntentActionAlipayHandleRedirect?,
        useStripeSDK: STPIntentActionUseStripeSDK?,
        oxxoDisplayDetails: STPIntentActionOXXODisplayDetails?,
        weChatPayRedirectToApp: STPIntentActionWechatPayRedirectToApp?,
        boletoDisplayDetails: STPIntentActionBoletoDisplayDetails?,
        verifyWithMicrodeposits: STPIntentActionVerifyWithMicrodeposits?,
        cashAppRedirectToApp: STPIntentActionCashAppRedirectToApp?,
        payNowDisplayQrCode: STPIntentActionPayNowDisplayQrCode?,
        konbiniDisplayDetails: STPIntentActionKonbiniDisplayDetails?,
        promptPayDisplayQrCode: STPIntentActionPromptPayDisplayQrCode?,
        swishHandleRedirect: STPIntentActionSwishHandleRedirect?,
        multibancoDisplayDetails: STPIntentActionMultibancoDisplayDetails?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.type = type
        self.redirectToURL = redirectToURL
        self.alipayHandleRedirect = alipayHandleRedirect
        self.useStripeSDK = useStripeSDK
        self.oxxoDisplayDetails = oxxoDisplayDetails
        self.weChatPayRedirectToApp = weChatPayRedirectToApp
        self.boletoDisplayDetails = boletoDisplayDetails
        self.verifyWithMicrodeposits = verifyWithMicrodeposits
        self.cashAppRedirectToApp = cashAppRedirectToApp
        self.payNowDisplayQrCode = payNowDisplayQrCode
        self.konbiniDisplayDetails = konbiniDisplayDetails
        self.promptPayDisplayQrCode = promptPayDisplayQrCode
        self.swishHandleRedirect = swishHandleRedirect
        self.multibancoDisplayDetails = multibancoDisplayDetails
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPIntentAction: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let rawType = dict["type"] as? String
        else {
            return nil
        }

        // Only set the type to a recognized value if we *also* have the expected sub-details.
        // ex: If the server said it was `.redirectToURL`, but decoding the
        // STPIntentActionRedirectToURL object fails, map type to `.unknown`
        var type = STPIntentActionType(string: rawType)
        var redirectToURL: STPIntentActionRedirectToURL?
        var alipayHandleRedirect: STPIntentActionAlipayHandleRedirect?
        var useStripeSDK: STPIntentActionUseStripeSDK?
        var oxxoDisplayDetails: STPIntentActionOXXODisplayDetails?
        var boletoDisplayDetails: STPIntentActionBoletoDisplayDetails?
        var weChatPayRedirectToApp: STPIntentActionWechatPayRedirectToApp?
        var verifyWithMicrodeposits: STPIntentActionVerifyWithMicrodeposits?
        var cashAppRedirectToApp: STPIntentActionCashAppRedirectToApp?
        var payNowDisplayQrCode: STPIntentActionPayNowDisplayQrCode?
        var konbiniDisplayDetails: STPIntentActionKonbiniDisplayDetails?
        var promptPayDisplayQrCode: STPIntentActionPromptPayDisplayQrCode?
        var swishHandleRedirect: STPIntentActionSwishHandleRedirect?
        var multibancoDisplayDetails: STPIntentActionMultibancoDisplayDetails?

        switch type {
        case .unknown:
            break
        case .redirectToURL:
            redirectToURL = STPIntentActionRedirectToURL.decodedObject(
                fromAPIResponse: dict["redirect_to_url"] as? [AnyHashable: Any]
            )
            if redirectToURL == nil {
                type = .unknown
            }
        case .useStripeSDK:
            useStripeSDK = STPIntentActionUseStripeSDK.decodedObject(
                fromAPIResponse: dict["use_stripe_sdk"] as? [AnyHashable: Any]
            )
            if useStripeSDK == nil {
                type = .unknown
            }
        case .OXXODisplayDetails:
            oxxoDisplayDetails = STPIntentActionOXXODisplayDetails.decodedObject(
                fromAPIResponse: dict["oxxo_display_details"] as? [AnyHashable: Any]
            )
            if oxxoDisplayDetails == nil {
                type = .unknown
            }
        case .alipayHandleRedirect:
            alipayHandleRedirect = STPIntentActionAlipayHandleRedirect.decodedObject(
                fromAPIResponse: dict["alipay_handle_redirect"] as? [AnyHashable: Any]
            )
            if alipayHandleRedirect == nil {
                type = .unknown
            }
        case .weChatPayRedirectToApp:
            weChatPayRedirectToApp = STPIntentActionWechatPayRedirectToApp.decodedObject(
                fromAPIResponse: dict["wechat_pay_redirect_to_ios_app"] as? [AnyHashable: Any]
            )
            if weChatPayRedirectToApp == nil {
                type = .unknown
            }
        case .boletoDisplayDetails:
            boletoDisplayDetails = STPIntentActionBoletoDisplayDetails.decodedObject(
                fromAPIResponse: dict["boleto_display_details"] as? [AnyHashable: Any]
            )
            if boletoDisplayDetails == nil {
                type = .unknown
            }
        case .BLIKAuthorize:
            break  // no additional details
        case .verifyWithMicrodeposits:
            verifyWithMicrodeposits = STPIntentActionVerifyWithMicrodeposits.decodedObject(
                fromAPIResponse: dict["verify_with_microdeposits"] as? [AnyHashable: Any]
            )
            if verifyWithMicrodeposits == nil {
                type = .unknown
            }
        case .upiAwaitNotification:
            break  // no additional details
        case .cashAppRedirectToApp:
            cashAppRedirectToApp = STPIntentActionCashAppRedirectToApp.decodedObject(
                fromAPIResponse: dict["cashapp_handle_redirect_or_display_qr_code"] as? [AnyHashable: Any]
            )
            if cashAppRedirectToApp == nil {
                type = .unknown
            }
        case .payNowDisplayQrCode:
            payNowDisplayQrCode = STPIntentActionPayNowDisplayQrCode.decodedObject(
                fromAPIResponse: dict["paynow_display_qr_code"] as? [AnyHashable: Any]
            )
            if payNowDisplayQrCode == nil {
                type = .unknown
            }
        case .konbiniDisplayDetails:
            konbiniDisplayDetails = STPIntentActionKonbiniDisplayDetails.decodedObject(
                fromAPIResponse: dict["konbini_display_details"] as? [AnyHashable: Any]
            )
            if konbiniDisplayDetails == nil {
                type = .unknown
            }
        case .promptpayDisplayQrCode:
            promptPayDisplayQrCode = STPIntentActionPromptPayDisplayQrCode.decodedObject(
                fromAPIResponse: dict["promptpay_display_qr_code"] as? [AnyHashable: Any]
            )
            if promptPayDisplayQrCode == nil {
                type = .unknown
            }
        case .swishHandleRedirect:
            swishHandleRedirect = STPIntentActionSwishHandleRedirect.decodedObject(
                fromAPIResponse: dict["swish_handle_redirect_or_display_qr_code"] as? [AnyHashable: Any]
            )
            if swishHandleRedirect == nil {
                type = .unknown
            }
        case .multibancoDisplayDetails:
            multibancoDisplayDetails = STPIntentActionMultibancoDisplayDetails.decodedObject(
                fromAPIResponse: dict["multibanco_display_details"] as? [AnyHashable: Any]
            )
            if multibancoDisplayDetails == nil {
                type = .unknown
            }
        }

        return STPIntentAction(
            type: type,
            redirectToURL: redirectToURL,
            alipayHandleRedirect: alipayHandleRedirect,
            useStripeSDK: useStripeSDK,
            oxxoDisplayDetails: oxxoDisplayDetails,
            weChatPayRedirectToApp: weChatPayRedirectToApp,
            boletoDisplayDetails: boletoDisplayDetails,
            verifyWithMicrodeposits: verifyWithMicrodeposits,
            cashAppRedirectToApp: cashAppRedirectToApp,
            payNowDisplayQrCode: payNowDisplayQrCode,
            konbiniDisplayDetails: konbiniDisplayDetails,
            promptPayDisplayQrCode: promptPayDisplayQrCode,
            swishHandleRedirect: swishHandleRedirect,
            multibancoDisplayDetails: multibancoDisplayDetails,
            allResponseFields: dict
        ) as? Self
    }

}

// MARK: - Deprecated
extension STPIntentAction {
    /// The details for authorizing via URL, when `type == STPIntentActionTypeRedirectToURL`
    /// @deprecated Use `redirectToURL` instead.
    @available(*, deprecated, message: "Use `redirectToURL` instead.", renamed: "redirectToURL")
    @objc public var authorizeWithURL: STPIntentActionRedirectToURL? {
        return redirectToURL
    }
}
