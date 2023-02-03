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
    func logImageSelectorIconDownloadedIfNeeded(paymentMethod: PaymentSheet.PaymentMethodType) {
        guard case .dynamic(let name) = paymentMethod else {
            return
        }
        self.logPaymentSheetEvent(event: .luxeImageSelectorIconDownloaded, params: ["payment_method": name])
    }
    func logImageSelectorIconFromBundleIfNeeded(paymentMethod: PaymentSheet.PaymentMethodType) {
        guard case .dynamic(let name) = paymentMethod else {
            return
        }
        self.logPaymentSheetEvent(event: .luxeImageSelectorIconFromBundle, params: ["payment_method": name])
    }
    func logImageSelectorIconNotFoundIfNeeded(paymentMethod: PaymentSheet.PaymentMethodType) {
        guard case .dynamic(let name) = paymentMethod else {
            return
        }
        self.logPaymentSheetEvent(event: .luxeImageSelectorIconNotFound, params: ["payment_method": name])
    }
}
