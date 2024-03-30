//
//  STPAnalyticsClient+CustomerSheet.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore

extension STPAnalyticsClient {
    // Screen presentation
    func logCSAddPaymentMethodScreenPresented() {
        self.logPaymentSheetEvent(event: .cs_add_payment_method_screen_presented)
    }
    func logCSSelectPaymentMethodScreenPresented() {
        self.logPaymentSheetEvent(event: .cs_select_payment_method_screen_presented)
    }

    // PM selection & Confirmation
    func logCSSelectPaymentMethodScreenConfirmedSavedPMSuccess(type: String?) {
        let paymentMethodType = type ?? "unknown"
        self.logPaymentSheetEvent(event: .cs_select_payment_method_screen_confirmed_savedpm_success,
                                  params: ["payment_method_type": paymentMethodType])
    }
    func logCSSelectPaymentMethodScreenConfirmedSavedPMFailure(type: String?) {
        let paymentMethodType = type ?? "unknown"
        self.logPaymentSheetEvent(event: .cs_select_payment_method_screen_confirmed_savedpm_failure,
                                  params: ["payment_method_type": paymentMethodType])
    }

    // Remove pm success/failure
    func logCSSelectPaymentMethodScreenRemovePMSuccess() {
        self.logPaymentSheetEvent(event: .cs_select_payment_method_screen_removepm_success)
    }
    func logCSSelectPaymentMethodScreenRemovePMFailure() {
        self.logPaymentSheetEvent(event: .cs_select_payment_method_screen_removepm_failure)
    }

    // Add via setup intent success/failure
    func logCSAddPaymentMethodViaSetupIntentSuccess() {
        self.logPaymentSheetEvent(event: .cs_add_payment_method_via_setupintent_success)
    }
    func logCSAddPaymentMethodViaSetupIntentCanceled() {
        self.logPaymentSheetEvent(event: .cs_add_payment_method_via_setupintent_canceled)
    }
    func logCSAddPaymentMethodViaSetupIntentFailure() {
        self.logPaymentSheetEvent(event: .cs_add_payment_method_via_setupintent_failure)
    }

    // Add via attach success/failure
    func logCSAddPaymentMethodViaCreateAttachSuccess() {
        self.logPaymentSheetEvent(event: .cs_add_payment_method_via_createAttach_success)
    }
    func logCSAddPaymentMethodViaCreateAttachFailure() {
        self.logPaymentSheetEvent(event: .cs_add_payment_method_via_createAttach_failure)
    }
}
