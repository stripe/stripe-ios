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
    case unknown

    public var debugDescription: String {
        switch self {
        case .missingPublishableKey: return "The publishable key is missing from the API client."
        case .unexpectedResponseFromStripeAPI: return "Unexpected response from Stripe API."
        case .unknown: return "An unknown error occurred."
        }
    }
}

extension PaymentMethodMessagingElement {

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
    }

    // Initialize element from API response
    // Uses this logic tree: https://trailhead.corp.stripe.com/docs/payment-method-messaging/pmme-platform/elements-mobile
    convenience init?(apiResponse: APIResponse, configuration: Configuration) async throws {
        // no content case
        guard let firstPaymentPlan = apiResponse.paymentPlanGroups.first else {
            return nil
        }

        if apiResponse.paymentPlanGroups.count == 1 {
            // single partner

            // invalid response scenario
            guard let infoUrl = firstPaymentPlan.content.learnMore?.url else {
                Self.logAPIError(apiClient: configuration.apiClient)
                throw PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI
            }
            guard let logo = try await Self.getIconSet(
                for: firstPaymentPlan.content.images,
                style: configuration.appearance.style
            ).first else {
                // This should never happen, but if it does we log an error and attempt to fall back to a multi-partner style
                //      (so that we can use the promotion text, which doesn't require a logo, instead of inline) without logos
                stpAssertionFailure("No images returned by API")
                Self.logAPIError(apiClient: configuration.apiClient)
                if let topLevelPromotion = apiResponse.content.promotion?.message {
                    self.init(
                        mode: .multiPartner(logos: []),
                        infoUrl: infoUrl,
                        promotion: topLevelPromotion,
                        appearance: configuration.appearance
                    )
                    return
                } else {
                    throw PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI
                }
            }

            if let inlinePromo = firstPaymentPlan.content.inlinePartnerPromotion?.message {
                // standard case, we display single partner style
                self.init(
                    mode: .singlePartner(logo: logo),
                    infoUrl: infoUrl,
                    promotion: inlinePromo,
                    appearance: configuration.appearance
                )
                return
            } else if let topLevelPromotion = apiResponse.content.promotion?.message {
                // fallback case, we don't have an inline promo so we use the main promo in a multi-partner style
                self.init(
                    mode: .multiPartner(logos: [logo]),
                    infoUrl: infoUrl,
                    promotion: topLevelPromotion,
                    appearance: configuration.appearance
                )
                return
            } else {
                // if we also don't have a top-level promo text, then this is a no content scenario
                return nil
            }
        } else {
            // multi-partner

            // invalid response scenario
            guard let infoUrl = apiResponse.content.learnMore?.url else {
                Self.logAPIError(apiClient: configuration.apiClient)
                throw PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI
            }

            // no content scenario
            guard let promotion = apiResponse.content.promotion?.message else {
                return nil
            }

            let apiImages = apiResponse.paymentPlanGroups.flatMap { $0.content.images }
            let logos = try await Self.getIconSet(for: apiImages, style: configuration.appearance.style)
            self.init(
                mode: .multiPartner(logos: logos),
                infoUrl: infoUrl,
                promotion: promotion,
                appearance: configuration.appearance
            )
            return
        }
    }

    private static func getIconSet(for iconUrls: [APIResponse.Image], style: Appearance.UserInterfaceStyle) async throws -> [LogoSet] {
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
                        async let lightImage = DownloadManager.sharedManager.downloadImage(url: image.lightThemePng.url)
                        async let darkImage = DownloadManager.sharedManager.downloadImage(url: image.darkThemePng.url)
                        let (light, dark) = try await (lightImage, darkImage)
                        return (index: i, iconSet: LogoSet(light: light, dark: dark, altText: image.text))
                    }
                case .alwaysLight:
                    // For all non-automatic styles, we fetch one image and use it for
                    //     both light and dark
                    taskGroup.addTask {
                        let lightImage = try await DownloadManager.sharedManager.downloadImage(url: image.lightThemePng.url)
                        return (index: i, iconSet: LogoSet(light: lightImage, dark: lightImage, altText: image.text))
                    }
                case .alwaysDark:
                    taskGroup.addTask {
                        let darkImage = try await DownloadManager.sharedManager.downloadImage(url: image.darkThemePng.url)
                        return (index: i, iconSet: LogoSet(light: darkImage, dark: darkImage, altText: image.text))
                    }
                case .flat:
                    taskGroup.addTask {
                        let flatImage = try await DownloadManager.sharedManager.downloadImage(url: image.flatThemePng.url)
                        return (index: i, iconSet: LogoSet(light: flatImage, dark: flatImage, altText: image.text))

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

    private static func logAPIError(apiClient: STPAPIClient) {
        let error = PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI
        let errorAnalytic = ErrorAnalytic(event: .unexpectedPMMEError, error: error)
        STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic, apiClient: apiClient)
    }
}

extension PaymentMethodMessagingElement.Appearance {
    var scaledFont: UIFont {
        UIFontMetrics.default.scaledFont(for: font, maximumPointSize: 25)
    }
}
