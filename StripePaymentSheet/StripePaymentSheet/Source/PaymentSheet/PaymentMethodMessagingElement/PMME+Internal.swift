//
//  PMME+Internal.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/9/25.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

enum PaymentMethodMessagingElementError: Error, LocalizedError {
    case missingPublishableKey
    case unexpectedResponseFromStripeAPI

    public var debugDescription: String {
        switch self {
        case .missingPublishableKey: return "The publishable key is missing from the API client."
        case .unexpectedResponseFromStripeAPI: return "Unexpected response from Stripe API."
        }
    }
}

extension PaymentMethodMessagingElement {

    /// Internal version of create() that allows injection of a DownloadManager for testing.
    /// - Parameter configuration: Configuration for the PaymentMethodMessagingElement.
    /// - Parameter downloadManager: The DownloadManager instance to use for downloading images.
    /// - Parameter analyticsClient: Optional analytics client for testing. Defaults to shared client.
    /// - Returns: A `CreationResult` object representing the result of the attempt to load the element.
    static func create(configuration: Configuration, downloadManager: DownloadManager, analyticsClient: STPAnalyticsClientProtocol) async -> CreationResult {
        // This being a singleton can theoretically cause problems when using multiple sessions-generating products at once
        // TODO(ocs-mobile): Make this not a singleton
        AnalyticsHelper.shared.generateSessionID()
        analyticsClient.addClass(toProductUsageIfNecessary: PaymentMethodMessagingElement.self)
        let analyticsHelper = PMMEAnalyticsHelper(configuration: configuration, analyticsClient: analyticsClient)
        analyticsHelper.logLoadStarted()

        do {
            let apiResponse = try await get(configuration: configuration)
            if let pmme = try await PaymentMethodMessagingElement(
                apiResponse: apiResponse,
                configuration: configuration,
                analyticsHelper: analyticsHelper,
                downloadManager: downloadManager
            ) {
                analyticsHelper.logLoadSucceeded(mode: pmme.mode)
                return .success(pmme)
            } else {
                analyticsHelper.logLoadSucceededNoContent()
                return .noContent
            }
        } catch {
            analyticsHelper.logLoadFailed(error: error)
            return .failed(error)
        }
    }

    enum Mode: Equatable {
        case singlePartner(logo: LogoSet)
        case multiPartner(logos: [LogoSet])
    }

    // A set of logo assets for light and dark mode.
    // ex: appearance.style = .automatic -> logoSet.light = light asset, logoSet.dark = dark asset
    //     appearance.style = .alwaysDark -> logoSet.light = dark asset, logoSet.dark = dark asset
    struct LogoSet: Equatable {
        let light: UIImage
        let dark: UIImage
        let altText: String
        let code: String
    }
}

extension PaymentMethodMessagingElement.Appearance {
    var scaledFont: UIFont {
        UIFontMetrics.default.scaledFont(for: font, maximumPointSize: 25)
    }

    // Returns a value scaled according to the font size
    func fontScaled(_ x: CGFloat) -> CGFloat {
        let defaultFontCapheight = PaymentMethodMessagingElement.Appearance().font.capHeight
        let xToFontHeightRatio = x / defaultFontCapheight
        return xToFontHeightRatio * scaledFont.capHeight
    }
}

@_spi(STP) extension PaymentMethodMessagingElement: STPAnalyticsProtocol {
    @_spi(STP) public nonisolated static let stp_analyticsIdentifier: String = "PaymentMethodMessagingElement"
}
