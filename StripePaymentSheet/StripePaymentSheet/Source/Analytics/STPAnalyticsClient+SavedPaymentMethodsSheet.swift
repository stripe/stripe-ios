//
//  STPAnalyticsClient+SavedPaymentMethodsSheet.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore

extension STPAnalyticsClient {
    // Screen presentation
    func logSPMSAddPaymentMethodScreenPresented() {
        self.logPaymentSheetEvent(event: .spms_add_payment_method_screen_presented)
    }
    func logSPMSSelectPaymentMethodScreenPresented() {
        self.logPaymentSheetEvent(event: .spms_select_payment_method_screen_presented)
    }

    // PM selection
    func logSPMSSelectPaymentMethodScreenSelectedSavedPM() {
        self.logPaymentSheetEvent(event: .spms_select_payment_method_screen_selected_savedpm)
    }

    // Remove pm success/failure
    func logSPMSSelectPaymentMethodScreenRemovePMSuccess() {
        self.logPaymentSheetEvent(event: .spms_select_payment_method_screen_removepm_success)
    }
    func logSPMSSelectPaymentMethodScreenRemovePMFailure() {
        self.logPaymentSheetEvent(event: .spms_select_payment_method_screen_removepm_failure)
    }

    // Add via setup intent success/failure
    func logSPMSAddPaymentMethodViaSetupIntentSuccess() {
        self.logPaymentSheetEvent(event: .spms_add_payment_method_via_setupintent_success)
    }
    func logSPMSAddPaymentMethodViaSetupIntentFailure() {
        self.logPaymentSheetEvent(event: .spms_add_payment_method_via_setupintent_failure)
    }

    // Add via attach success/failure
    func logSPMSAddPaymentMethodViaCreateAttachSuccess() {
        self.logPaymentSheetEvent(event: .spms_add_payment_method_via_createAttach_success)
    }
    func logSPMSAddPaymentMethodViaCreateAttachFailure() {
        self.logPaymentSheetEvent(event: .spms_add_payment_method_via_createAttach_failure)
    }
}
