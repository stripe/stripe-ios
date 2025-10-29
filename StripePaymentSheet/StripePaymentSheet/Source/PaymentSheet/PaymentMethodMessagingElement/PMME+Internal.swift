//
//  PMME+Internal.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/23/25.
//

import Foundation
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

    // Factory method that creates a UIView for the PMME
    static func createUIView(viewData: ViewData, didUpdateHeight: ((CGFloat) -> Void)? = nil) -> UIView {
        switch viewData.mode {
        case .singlePartner(let logo):
            return PMMESinglePartnerView(
                logoSet: logo,
                infoUrl: viewData.infoUrl,
                promotion: viewData.promotion,
                appearance: viewData.appearance,
                didUpdateHeight: didUpdateHeight
            )
        case .multiPartner(let logos):
            return PMMEMultiPartnerView(
                logoSets: logos,
                infoUrl: viewData.infoUrl,
                promotion: viewData.promotion,
                appearance: viewData.appearance,
                didUpdateHeight: didUpdateHeight
            )
        }
    }
}

extension PaymentMethodMessagingElement.Appearance {
    var scaledFont: UIFont {
        UIFontMetrics.default.scaledFont(for: font, maximumPointSize: 25)
    }
}
