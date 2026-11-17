//
//  SheetChangedMessageHandler.swift
//  StripeConnect
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// The content of a native sheet an inline component opened changed height, or its dialog stayed open after the
/// sheet closed and should be shown again
class SheetChangedMessageHandler: ScriptMessageHandler<SheetChangedMessageHandler.Payload> {
    struct Payload: Codable, Equatable {
        /// The sheet's id from its window URL
        let sheetId: String
        /// The sheet's content height, in CSS pixels
        let height: Double
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
