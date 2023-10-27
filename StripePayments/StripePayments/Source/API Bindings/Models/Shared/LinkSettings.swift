//
//  LinkSettings.swift
//  StripePayments
//
//  Created by Ramon Torres on 4/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// For internal SDK use only
@objc(STP_Internal_LinkSettings)
@_spi(STP) public final class LinkSettings: NSObject, STPAPIResponseDecodable {
    @_spi(STP) @frozen public enum FundingSource: String {
        case card = "CARD"
        case bankAccount = "BANK_ACCOUNT"
    }

    @_spi(STP) @frozen public enum PopupWebviewOption: String {
        case shared
        case ephemeral
    }

    @_spi(STP) public let fundingSources: Set<FundingSource>
    @_spi(STP) public let popupWebviewOption: PopupWebviewOption?

    @_spi(STP) public let allResponseFields: [AnyHashable: Any]

    @_spi(STP) public init(
        fundingSources: Set<FundingSource>,
        popupWebviewOption: PopupWebviewOption?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.fundingSources = fundingSources
        self.popupWebviewOption = popupWebviewOption
        self.allResponseFields = allResponseFields
    }

    @_spi(STP) public static func decodedObject(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> Self? {
        guard
            let response = response,
            let fundingSourcesStrings = response["link_funding_sources"] as? [String]
        else {
            return nil
        }

        // Server may send down funding sources we haven't implemented yet, so we'll just ignore any unknown sources
        let validFundingSources = Set(fundingSourcesStrings.compactMap(FundingSource.init))

        let webviewOption = PopupWebviewOption(rawValue: response["link_popup_webview_option"] as? String ?? "")

        return LinkSettings(
            fundingSources: validFundingSources,
            popupWebviewOption: webviewOption,
            allResponseFields: response
        ) as? Self
    }

}
