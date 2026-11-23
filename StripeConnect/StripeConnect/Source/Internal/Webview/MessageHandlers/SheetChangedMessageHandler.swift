//
//  SheetChangedMessageHandler.swift
//  StripeConnect
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// A native sheet an inline component opened changed height or whether it can be dismissed
class SheetChangedMessageHandler: ScriptMessageHandler<SheetChangedMessageHandler.Payload> {
    struct Payload: Codable, Equatable {
        /// The sheet's id from its window URL
        let sheetId: String
        /// The sheet's content height, in CSS pixels
        let height: Double
        /// Whether a swipe or an outside tap can close the sheet. Missing means true.
        let dismissible: Bool?
    }

    init(sourcePolicy: STPWebMessageSourcePolicy,
         analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (Payload) -> Void) {
        super.init(name: "sheetChanged",
                   sourcePolicy: sourcePolicy,
                   analyticsClient: analyticsClient,
                   didReceiveMessage: didReceiveMessage)
    }
}
