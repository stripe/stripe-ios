//
//  AdaptivePricingFlagImageManager.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/13/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

/// Downloads and caches country flag images for the adaptive pricing currency selector.
///
/// Flag images are prefetched during ``Checkout.init(clientSecret:configuration:apiClient:)``
/// so they are available immediately when ``Checkout.CurrencySelectorView`` appears.
/// If either download fails, both currencies fall back to emoji flags.
@MainActor
final class AdaptivePricingFlagImageManager {
    private typealias CurrencyCode = CurrencySelectorUtilities.CurrencyCode

    private let downloadManager: DownloadManager
    private let analyticsClient: STPAnalyticsClient

    private var imagesByCurrencyCode: [String: UIImage]?

    init(analyticsClient: STPAnalyticsClient = .sharedClient) {
        self.downloadManager = DownloadManager(
            urlSessionConfiguration: StripeAPIConfiguration.sharedUrlSessionConfiguration
        )
        self.analyticsClient = analyticsClient
    }

    // MARK: - Prefetch

    /// Downloads flag images for the local and integration currencies.
    ///
    /// This method is a no-op when adaptive pricing is inactive or only one
    /// currency is present. Calling it again replaces any previously cached images.
    func prefetchFlagImages(for session: STPCheckoutSession) async {
        // Adaptive pricing is inactive or there's only one currency — no flags needed.
        guard let (local, integration) = requiredCurrencyPair(for: session) else {
            imagesByCurrencyCode = nil
            return
        }

        let localCountry = Self.countryCode(for: local)
        let integrationCountry = Self.countryCode(for: integration)

        let localResult = await downloadFlagImage(countryCode: localCountry)
        let integrationResult = await downloadFlagImage(countryCode: integrationCountry)

        switch (localResult, integrationResult) {
        case (.success(let localImage), .success(let integrationImage)):
            imagesByCurrencyCode = [
                local.apiValue: localImage,
                integration.apiValue: integrationImage,
            ]
        case let (localResult, integrationResult):
            imagesByCurrencyCode = nil
            if case .failure(let url) = localResult {
                logFailure(countryCode: localCountry, url: url)
            }
            if case .failure(let url) = integrationResult {
                logFailure(countryCode: integrationCountry, url: url)
            }
        }
    }

    // MARK: - Access

    /// Returns an attributed string containing the flag for the given currency code.
    ///
    /// If a downloaded image is available, the string contains a text attachment;
    /// otherwise it contains the corresponding emoji flag.
    func flagIcon(for currency: String, font: UIFont) -> NSAttributedString {
        let code = CurrencyCode(currency)
        if let image = imagesByCurrencyCode?[code.apiValue] {
            return .attributedStringForImage(image.withRenderingMode(.alwaysOriginal), font: font, additionalScale: 1.5)
        }
        let emoji = CurrencySelectorUtilities.flagEmoji(for: code)
        return NSAttributedString(string: emoji)
    }

    // MARK: - Private helpers

    private func requiredCurrencyPair(for session: STPCheckoutSession) -> (local: CurrencyCode, integration: CurrencyCode)? {
        guard session.adaptivePricingActive,
              session.localizedPricesMetas.count > 1,
              let meta = session.exchangeRateMeta else {
            return nil
        }

        let local = CurrencyCode(meta.localizedCurrency)
        let integration = CurrencyCode(meta.integrationCurrency)
        guard local != integration else { return nil }

        return (local, integration)
    }

    /// Returns the two-letter country code for the given currency (e.g. `"GB"` from `"GBP"`).
    private static func countryCode(for currency: CurrencyCode) -> String {
        String(currency.displayValue.prefix(2))
    }

    // MARK: Image download

    private enum FlagResult {
        case success(UIImage)
        case failure(URL)
    }

    private func downloadFlagImage(countryCode: String) async -> FlagResult {
        let url = makeFlagImageURL(countryCode: countryCode)
        do {
            let image = try await downloadManager.downloadImage(url: url)
            return .success(image)
        } catch {
            return .failure(url)
        }
    }

    private func logFailure(countryCode: String, url: URL) {
        analyticsClient.log(
            analytic: PaymentSheetAnalytic(
                event: .adaptivePricingFlagImageLoadFailed,
                additionalParams: [
                    "country_code": countryCode,
                    "url": url.absoluteString,
                ]
            )
        )
    }

    private static let flagBaseURL = "https://b.stripecdn.com/ocs-mobile/assets/flags"
    private static let imageProxyURL = "https://img.stripecdn.com/cdn-cgi/image"

    private func makeFlagImageURL(countryCode: String) -> URL {
        #if os(visionOS)
        let dpr = 1
        #else
        let dpr = Int(UIScreen.main.scale.rounded(.up))
        #endif
        let origin = "\(Self.flagBaseURL)/\(countryCode.uppercased()).png"
        // Safe to force-unwrap: the URL components are all static constants plus a country code.
        return URL(string: "\(Self.imageProxyURL)/format=auto,height=16,dpr=\(dpr)/\(origin)")!
    }
}
