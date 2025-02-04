//
//  CustomerSession.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments
/// CustomerSession information, delivered in the `v1/elements/sessions` response.
/// - Seealso: https://git.corp.stripe.com/stripe-internal/pay-server/blob/master/api/lib/customer_session/resource/customer_session_client_resource.rb
struct CustomerSession: Equatable, Hashable {
    let id: String
    let liveMode: Bool
    let apiKey: String
    let apiKeyExpiry: Int
    let customer: String
    let mobilePaymentElementComponent: MobilePaymentElementComponent
    let customerSheetComponent: CustomerSheetComponent

    /// Helper method to decode the `v1/elements/sessions` response's `external_payment_methods_data` hash.
    /// - Parameter response: The value of the `external_payment_methods_data` key in the `v1/elements/sessions` response.
    public static func decoded(fromAPIResponse response: [AnyHashable: Any]?) -> CustomerSession? {
        guard let response,
              let id = response["id"] as? String,
              let liveMode = response["livemode"] as? Bool,
              let apiKey = response["api_key"] as? String,
              let apiKeyExpiry = response["api_key_expiry"] as? Int,
              let customer = response["customer"] as? String,
              let componentsDict = response["components"] as? [AnyHashable: Any],
              let mobilePaymentElementDict = componentsDict["mobile_payment_element"] as? [AnyHashable: Any],
              let mobilePaymentElementEnabled = mobilePaymentElementDict["enabled"] as? Bool,
              let customerSheetDict = componentsDict["customer_sheet"] as? [AnyHashable: Any],
              let customerSheetEnabled = customerSheetDict["enabled"] as? Bool
        else {
            return nil
        }

        var mobilePaymentElementComponent: MobilePaymentElementComponent
        if mobilePaymentElementEnabled {
            guard let mobilePaymentElementFeaturesDict = mobilePaymentElementDict["features"] as? [AnyHashable: Any],
                  let paymentMethodSave = mobilePaymentElementFeaturesDict["payment_method_save"] as? String,
                  let paymentMethodRemove = mobilePaymentElementFeaturesDict["payment_method_remove"] as? String else {
                return nil
            }
            let paymentMethodRemoveLast = mobilePaymentElementFeaturesDict["payment_method_remove_last"] as? String ?? "enabled"
            let paymentMethodSetAsDefault = mobilePaymentElementFeaturesDict["payment_method_set_as_default"] as? String ?? "disabled"

            var allowRedisplayOverrideValue: STPPaymentMethodAllowRedisplay?
            if let allowRedisplayOverride = mobilePaymentElementFeaturesDict["payment_method_save_allow_redisplay_override"] as? String {
                allowRedisplayOverrideValue = STPPaymentMethod.allowRedisplay(from: allowRedisplayOverride)
            }

            mobilePaymentElementComponent = MobilePaymentElementComponent(enabled: true,
                                                                          features: MobilePaymentElementComponentFeature(paymentMethodSave: paymentMethodSave == "enabled",
                                                                                                                         paymentMethodRemove: paymentMethodRemove == "enabled",
                                                                                                                         paymentMethodRemoveLast: paymentMethodRemoveLast == "enabled",
                                                                                                                         paymentMethodSaveAllowRedisplayOverride: allowRedisplayOverrideValue,
                                                                                                                         paymentMethodSetAsDefault: paymentMethodSetAsDefault == "enabled"))
        } else {
            mobilePaymentElementComponent = MobilePaymentElementComponent(enabled: false, features: nil)
        }

        var customerSheetComponent: CustomerSheetComponent
        if customerSheetEnabled {
            guard let customerSheetFeaturesDict = customerSheetDict["features"] as? [AnyHashable: Any],
                  let paymentMethodRemove = customerSheetFeaturesDict["payment_method_remove"] as? String else {
                return nil
            }
            let paymentMethodRemoveLast = customerSheetFeaturesDict["payment_method_remove_last"] as? String ?? "enabled"
            let paymentMethodSyncDefault = customerSheetFeaturesDict["payment_method_sync_default"] as? String ?? "disabled"
            customerSheetComponent = CustomerSheetComponent(enabled: true,
                                                            features: CustomerSheetComponentFeature(paymentMethodRemove: paymentMethodRemove == "enabled",
                                                                                                    paymentMethodRemoveLast: paymentMethodRemoveLast == "enabled",
                                                                                                    paymentMethodSyncDefault: paymentMethodSyncDefault == "enabled"))
        } else {
            customerSheetComponent = CustomerSheetComponent(enabled: false, features: nil)
        }

        return CustomerSession(id: id,
                               liveMode: liveMode,
                               apiKey: apiKey,
                               apiKeyExpiry: apiKeyExpiry,
                               customer: customer,
                               mobilePaymentElementComponent: mobilePaymentElementComponent,
                               customerSheetComponent: customerSheetComponent)
    }
}

struct MobilePaymentElementComponent: Equatable, Hashable {
    let enabled: Bool
    let features: MobilePaymentElementComponentFeature?
}

/// Features on CustomerSessions when the paymentSheet component is enabled:
/// https://docs.corp.stripe.com/api/customer_sessions/object#customer_session_object-components-mobile_payment_element-features
struct MobilePaymentElementComponentFeature: Equatable, Hashable {
    let paymentMethodSave: Bool
    let paymentMethodRemove: Bool
    let paymentMethodRemoveLast: Bool
    let paymentMethodSaveAllowRedisplayOverride: STPPaymentMethodAllowRedisplay?
    let paymentMethodSetAsDefault: Bool
}

struct CustomerSheetComponent: Equatable, Hashable {
    let enabled: Bool
    let features: CustomerSheetComponentFeature?
}

struct CustomerSheetComponentFeature: Equatable, Hashable {
    let paymentMethodRemove: Bool
    let paymentMethodRemoveLast: Bool
    let paymentMethodSyncDefault: Bool
}
