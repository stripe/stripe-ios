//
//  RefreshNotificationBannerSender.swift
//  StripeConnect
//

import Foundation

enum RefreshNotificationBannerSender {
    static func sender() -> CallSetterWithSerializableValueSender<String> {
        CallSetterWithSerializableValueSender(payload: .init(
            setter: "setMobileNotificationRefreshToken",
            value: UUID().uuidString
        ))
    }
}
