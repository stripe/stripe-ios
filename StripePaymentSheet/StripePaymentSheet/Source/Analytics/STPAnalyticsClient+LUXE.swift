//
//  STPAnalyticsClient+LUXE.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore

extension STPAnalyticsClient {
    func logLUXESerializeFailure() {
        self.logPaymentSheetEvent(event: .luxeSerializeFailure)
    }

    func logLUXEUnknownActionsFailure() {
        self.logPaymentSheetEvent(event: .luxeUnknownActionsFailure)
    }

    func logLUXESpecSerilizeFailure(error: Error?, paymentMethod: String) {
        self.logPaymentSheetEvent(event: .luxeSpecSerializeFailure, error: error, params: ["payment_method": paymentMethod])
    }

    func logImageSelectorIconDownloadedIfNeeded(paymentMethod: PaymentSheet.PaymentMethodType) {
        self.logPaymentSheetEvent(event: .luxeImageSelectorIconDownloaded, params: ["payment_method": paymentMethod.identifier])
    }

    func logImageSelectorIconFromBundleIfNeeded(paymentMethod: PaymentSheet.PaymentMethodType) {
        self.logPaymentSheetEvent(event: .luxeImageSelectorIconFromBundle, params: ["payment_method": paymentMethod.identifier])
    }
    func logImageSelectorIconNotFoundIfNeeded(paymentMethod: PaymentSheet.PaymentMethodType) {
        self.logPaymentSheetEvent(event: .luxeImageSelectorIconNotFound, params: ["payment_method": paymentMethod.identifier])
    }
}
