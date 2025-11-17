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

    // Initialize element from API response
    // Uses this logic tree: https://trailhead.corp.stripe.com/docs/payment-method-messaging/pmme-platform/elements-mobile
    convenience init?(apiResponse: APIResponse, configuration: Configuration, analyticsHelper: PMMEAnalyticsHelper, downloadManager: DownloadManager = .sharedManager) async throws {
        if apiResponse.paymentPlanGroups.count == 1, let paymentPlan = apiResponse.paymentPlanGroups.first {
            // case 1: 1 payment plan

            // no content case - expected
            guard let inlinePromo = paymentPlan.content.inlinePartnerPromotion?.message else {
                return nil
            }

            // unexpected / error cases
            guard let infoUrl = paymentPlan.content.learnMore?.url else {
                Self.assertAndLogMissingField("info_url", apiClient: configuration.apiClient)
                return nil
            }
            guard let logo = try await Self.getIconSet(
                for: paymentPlan.content.images,
                style: configuration.appearance.style,
                downloadManager: downloadManager
            ).first else {
                // There were no images in `paymentPlan.content.images`
                // This should never happen, but if it does we log an error and attempt to fall back to a multi-partner style
                //      (so that we can use the promotion text, which doesn't require a logo, instead of inline) without logos
                Self.assertAndLogMissingField("logo", apiClient: configuration.apiClient)

                if let topLevelPromotion = apiResponse.content.promotion?.message {
                    self.init(
                        mode: .multiPartner(logos: []),
                        infoUrl: infoUrl,
                        promotion: topLevelPromotion,
                        appearance: configuration.appearance,
                        analyticsHelper: analyticsHelper
                    )
                    return
                } else {
                    // We already log the missing logos scenario above, so no need to do so here
                    throw PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI
                }
            }
            // success
            self.init(
                mode: .singlePartner(logo: logo),
                infoUrl: infoUrl,
                promotion: inlinePromo,
                appearance: configuration.appearance,
                analyticsHelper: analyticsHelper
            )
            return
        } else {
            // case 2: 0 or 2+ payment plans

            // no content case - expected
            guard let promo = apiResponse.content.promotion?.message else {
                return nil
            }

            // unexpected / error case
            guard let infoUrl = apiResponse.content.learnMore?.url else {
                Self.assertAndLogMissingField("info_url", apiClient: configuration.apiClient)
                return nil
            }

            // Use the list of images returned as the source of truth for what images to display and thus don't validate
            let apiImages = apiResponse.paymentPlanGroups.flatMap { $0.content.images }
            let logos = try await Self.getIconSet(
                for: apiImages,
                style: configuration.appearance.style,
                downloadManager: downloadManager
            )

            // success
            self.init(
                mode: .multiPartner(logos: logos),
                infoUrl: infoUrl,
                promotion: promo,
                appearance: configuration.appearance,
                analyticsHelper: analyticsHelper
            )
        }
    }

    private static func assertAndLogMissingField(_ missingField: String, apiClient: STPAPIClient) {
        stpAssertionFailure("Missing expected field from API response: \(missingField)")
        let error = PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI
        let errorAnalytic = ErrorAnalytic(event: .unexpectedPMMEError, error: error, additionalNonPIIParams: ["missing_field": "info_url"])
        STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic, apiClient: apiClient)
    }

    // Throws when the underlying downloadManager throws
    private static func getIconSet(for iconUrls: [APIResponse.Image], style: Appearance.UserInterfaceStyle, downloadManager: DownloadManager) async throws -> [LogoSet] {
        // Fetch all images concurrently
        // We want to preserve the order of the icons as provided by the API,
        //     so we have tasks return their index along with the image
        return try await withThrowingTaskGroup(of: (index: Int, iconSet: LogoSet).self, returning: [LogoSet].self) { taskGroup in
            // At some point in the future we may want to use the icons, but for now we just use logos
            for (i, image) in iconUrls.filter({ $0.role == "logo" }).enumerated() {
                switch style {
                case .automatic:
                    // For the automatic interface style, we fetch both dark and light
                    //     since the device interface style may change at any time
                    //     and we don't want to have to re-fetch the images
                    taskGroup.addTask {
                        async let lightImage = downloadManager.downloadImage(url: image.lightThemePng.url)
                        async let darkImage = downloadManager.downloadImage(url: image.darkThemePng.url)
                        let (light, dark) = try await (lightImage, darkImage)
                        return (
                            index: i,
                            iconSet: LogoSet(
                                light: light,
                                dark: dark,
                                altText: image.text,
                                code: image.paymentMethodType
                            )
                        )
                    }
                case .alwaysLight:
                    // For all non-automatic styles, we fetch one image and use it for
                    //     both light and dark
                    taskGroup.addTask {
                        let lightImage = try await downloadManager.downloadImage(url: image.lightThemePng.url)
                        return (
                            index: i,
                            iconSet: LogoSet(
                                light: lightImage,
                                dark: lightImage,
                                altText: image.text,
                                code: image.paymentMethodType
                            )
                        )
                    }
                case .alwaysDark:
                    taskGroup.addTask {
                        let darkImage = try await downloadManager.downloadImage(url: image.darkThemePng.url)
                        return (
                            index: i,
                            iconSet: LogoSet(
                                light: darkImage,
                                dark: darkImage,
                                altText: image.text,
                                code: image.paymentMethodType
                            )
                        )
                    }
                case .flat:
                    taskGroup.addTask {
                        let flatImage = try await downloadManager.downloadImage(url: image.flatThemePng.url)
                        return (
                            index: i,
                            iconSet: LogoSet(
                                light: flatImage,
                                dark: flatImage,
                                altText: image.text,
                                code: image.paymentMethodType
                            )
                        )
                    }
                }
            }

            // The tasks can complete in any order, so we place them back in the correct index
            var icons = [LogoSet?](repeating: nil, count: iconUrls.count)
            for try await result in taskGroup {
                icons[result.index] = result.iconSet
            }

            // All array elements should now be non-nil, but we need to convert
            //    from [IconSet?] to [IconSet]
            return icons.compactMap { $0 }
        }
    }
}

extension PaymentMethodMessagingElement.Appearance {
    var scaledFont: UIFont {
        UIFontMetrics.default.scaledFont(for: font, maximumPointSize: 25)
    }
}

extension PaymentMethodMessagingElement: STPAnalyticsProtocol {
    @_spi(STP) public nonisolated static let stp_analyticsIdentifier: String = "PaymentMethodMessagingElement"
}
