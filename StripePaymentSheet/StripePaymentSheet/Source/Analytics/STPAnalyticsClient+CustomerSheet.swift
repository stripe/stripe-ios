//
//  STPAnalyticsClient+CustomerSheet.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
extension STPAnalyticsClient {
    // Screen presentation
    func logCSAddPaymentMethodScreenPresented() {
        self.logPaymentSheetEvent(event: .cs_add_payment_method_screen_presented)
    }
    func logCSSelectPaymentMethodScreenPresented() {
        self.logPaymentSheetEvent(event: .cs_select_payment_method_screen_presented)
    }

    // PM selection & Confirmation
    func logCSSelectPaymentMethodScreenConfirmedSavedPMSuccess(paymentOptionSelection: CustomerSheet.PaymentOptionSelection, cardArtEnabled: Bool = false, syncDefaultEnabled: Bool? = nil) {
        let params = csConfirmedSavedPMParams(paymentOptionSelection: paymentOptionSelection, cardArtEnabled: cardArtEnabled, syncDefaultEnabled: syncDefaultEnabled)
        self.logPaymentSheetEvent(event: .cs_select_payment_method_screen_confirmed_savedpm_success,
                                  params: params)
    }
    func logCSSelectPaymentMethodScreenConfirmedSavedPMFailure(paymentOptionSelection: CustomerSheet.PaymentOptionSelection, cardArtEnabled: Bool = false, syncDefaultEnabled: Bool? = nil) {
        let params = csConfirmedSavedPMParams(paymentOptionSelection: paymentOptionSelection, cardArtEnabled: cardArtEnabled, syncDefaultEnabled: syncDefaultEnabled)
        self.logPaymentSheetEvent(event: .cs_select_payment_method_screen_confirmed_savedpm_failure,
                                  params: params)
    }

    private func csConfirmedSavedPMParams(paymentOptionSelection: CustomerSheet.PaymentOptionSelection, cardArtEnabled: Bool, syncDefaultEnabled: Bool?) -> [String: Any] {
        var params: [String: Any] = [:]
        switch paymentOptionSelection {
        case .applePay:
            params["payment_method_type"] = "apple_pay"
        case .paymentMethod(let paymentMethod, _):
            params["payment_method_type"] = STPPaymentMethod.string(from: paymentMethod.type) ?? "unknown"
            params["has_card_art"] = cardArtEnabled && paymentMethod.card?.cardArt?.artImage?.url != nil
        }
        if let syncDefaultEnabled {
            params["sync_default_enabled"] = syncDefaultEnabled
        }
        return params
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
