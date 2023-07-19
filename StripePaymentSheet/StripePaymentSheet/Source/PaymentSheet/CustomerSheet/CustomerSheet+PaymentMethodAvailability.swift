//
//  CustomerSheet+PaymentMethodAvailability.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments

extension CustomerSheet {
    //TODO: Add .USBankAccount when ready to launch
    static var supportedPaymentMethods: [STPPaymentMethodType] = [.card]
}

extension CustomerSheet.Configuration {

    // Called internally from CustomerSheet to determine what payment methods to show on add screen
    func supportedPaymentMethodTypesForAdd(customerAdapter: CustomerAdapter) -> [STPPaymentMethodType] {
        return self.dedupedPaymentMethodTypes.filter { type in
            var isSupported = CustomerSheet.supportedPaymentMethods.contains(type)
            if type == .USBankAccount {
                if !FinancialConnectionsSDKAvailability.isFinancialConnectionsSDKAvailable {
                    #if DEBUG
                    print("[Stripe SDK]: CustomerSheet:\(PaymentSheet.PaymentMethodTypeRequirement.financialConnectionsSDK.debugDescription)")
                    #endif
                    isSupported = false
                }
                if !customerAdapter.canCreateSetupIntents {
                    #if DEBUG
                    print("[Stripe SDK]: CustomerSheet - customerAdapater must be able to create setupIntents")
                    #endif
                    isSupported = false
                }
            }
            return isSupported
        }
    }

    // Called internally from CustomerSheet to determine what payment methods to query for
    func supportedPaymentMethodTypesForList() -> [STPPaymentMethodType] {
        self.dedupedPaymentMethodTypes.filter { type in
            CustomerSheet.supportedPaymentMethods.contains(type)
        }
    }

    var dedupedPaymentMethodTypes: [STPPaymentMethodType] {
        var dedupeSet: Set<STPPaymentMethodType> = []
        return self.paymentMethodTypes.filter { type in
            guard !dedupeSet.contains(type) else {
                return false
            }
            dedupeSet.insert(type)
            return true
        }
    }
}
extension CustomerSheet.Configuration {
    func validate() {
#if DEBUG
        // Check that there are no duplicates
        let setSupportedPaymentMethods = Set(self.paymentMethodTypes)
        if setSupportedPaymentMethods.count != self.paymentMethodTypes.count {
            print("[Stripe SDK]: CustomerSheet found duplicate payment methods in \(self.paymentMethodTypes)")
        }

        // Check if linked if using USBankAccount
        if self.paymentMethodTypes.contains(.USBankAccount) && !FinancialConnectionsSDKAvailability.isFinancialConnectionsSDKAvailable {
            print("[Stripe SDK]: CustomerSheet:\(PaymentSheet.PaymentMethodTypeRequirement.financialConnectionsSDK.debugDescription)")
        }

        // Check against supported payment method types
        for paymentMethodType in self.paymentMethodTypes {
            if !CustomerSheet.supportedPaymentMethods.contains(paymentMethodType) {
                print("[Stripe SDK]: CustomerSheet does not currently support payment method type: \(paymentMethodType)")
            }
        }
#endif
        if self.paymentMethodTypes.isEmpty {
            assertionFailure("[Stripe SDK]: CustomerSheet configuration invalid - paymentMethodTypes empty")
        }
    }
}

extension Array where Element == STPPaymentMethodType {
    // Internal Helper used for displaying payment method types to add
    func toPaymentSheetPaymentMethodTypes() -> [PaymentSheet.PaymentMethodType] {
        var uniquePMTypes: Set<STPPaymentMethodType> = []

        var pmTypes: [PaymentSheet.PaymentMethodType] = []
        for pm in self {
            guard let paymentMethodString = STPPaymentMethod.string(from: pm) else {
                continue
            }
            if uniquePMTypes.contains(pm) {
                #if DEBUG
                print("[Stripe SDK]: CustomerSheet found duplicate payment method:\(paymentMethodString)")
                #endif
            } else {
                uniquePMTypes.insert(pm)
                pmTypes += [PaymentSheet.PaymentMethodType(from: paymentMethodString)]
            }
        }
        return pmTypes
    }
}
