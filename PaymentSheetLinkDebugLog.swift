//
//  PaymentSheetLinkDebugLog.swift
//  StripePaymentSheet
//

import Foundation

extension Notification.Name {
    static let stpPaymentSheetLinkDebugLogDidEmit = Notification.Name("STP_PaymentSheetLinkDebugLogDidEmit")
}

func emitPaymentSheetLinkDebugLog(_ message: String) {
    #if DEBUG
    DispatchQueue.main.async {
        NotificationCenter.default.post(
            name: .stpPaymentSheetLinkDebugLogDidEmit,
            object: nil,
            userInfo: ["message": message]
        )
    }
    #endif
}
