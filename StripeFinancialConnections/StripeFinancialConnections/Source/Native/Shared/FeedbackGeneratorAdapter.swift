//
//  FeedbackGeneratorAdapter.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 3/6/24.
//

import Foundation
import UIKit

final class FeedbackGeneratorAdapter {

    private init() {}

    static func buttonTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func selectionChanged() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func errorOccurred() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func successOccurred() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
