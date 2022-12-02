//
//  LinkAccountContext.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 7/18/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

final class LinkAccountContext {

    static let shared: LinkAccountContext = .init()

    private let accountChangedNotificationName = Notification.Name(
        rawValue: "com.stripe.link.accountChangedNotification"
    )

    private let notificationCenter: NotificationCenter = .init()

    /// The current Link account, whether is verified or not.
    var account: PaymentSheetLinkAccount? {
        didSet {
            notificationCenter.post(name: accountChangedNotificationName, object: account)
        }
    }

    private init() {}

    /// Registers an observer to be notified when the current account changes.
    ///
    /// Unregister an observer to stop receiving notifications by calling `removeObserver(_:)`.
    func addObserver(_ observer: Any, selector: Selector) {
        notificationCenter.addObserver(
            observer,
            selector: selector,
            name: accountChangedNotificationName,
            object: nil
        )
    }

    /// Unregisters an observer to stop receiving account change notifications.
    func removeObserver(_ observer: Any) {
        notificationCenter.removeObserver(observer)
    }

}
