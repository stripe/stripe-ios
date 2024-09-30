//
//  LinkSettings.swift
//  StripePayments
//
//  Created by Ramon Torres on 4/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

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
    @_spi(STP) public let passthroughModeEnabled: Bool?
    @_spi(STP) public let disableSignup: Bool?
    @_spi(STP) public let linkMode: LinkMode?
    @_spi(STP) public let linkFlags: [String: Bool]?

    @_spi(STP) public let allResponseFields: [AnyHashable: Any]

    @_spi(STP) public init(
        fundingSources: Set<FundingSource>,
        popupWebviewOption: PopupWebviewOption?,
        passthroughModeEnabled: Bool?,
        disableSignup: Bool?,
        linkMode: LinkMode?,
        linkFlags: [String: Bool]?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.fundingSources = fundingSources
        self.popupWebviewOption = popupWebviewOption
        self.passthroughModeEnabled = passthroughModeEnabled
        self.disableSignup = disableSignup
        self.linkMode = linkMode
        self.linkFlags = linkFlags
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
        let passthroughModeEnabled = response["link_passthrough_mode_enabled"] as? Bool ?? false
        let disableSignup = response["link_mobile_disable_signup"] as? Bool ?? false
        let linkMode = (response["link_mode"] as? String).flatMap { LinkMode(rawValue: $0) }

        // Collect the flags for the URL generator
        let linkFlags = response.reduce(into: [String: Bool]()) { partialResult, element in
            if let key = element.key as? String, let value = element.value as? Bool {
                partialResult[key] = value
            }
        }

        return LinkSettings(
            fundingSources: validFundingSources,
            popupWebviewOption: webviewOption,
            passthroughModeEnabled: passthroughModeEnabled,
            disableSignup: disableSignup,
            linkMode: linkMode,
            linkFlags: linkFlags,
            allResponseFields: response
        ) as? Self
    }

}
