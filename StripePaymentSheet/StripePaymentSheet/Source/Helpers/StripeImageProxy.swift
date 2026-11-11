//
//  StripeImageProxy.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
import UIKit

/// Builds URLs that fetch an image through Stripe's image proxy at img.stripecdn.com, resized to the height it's drawn at.
enum StripeImageProxy {
    enum Format: String {
        /// Lets the proxy pick the format from the request's `Accept` header.
        case auto
        case png
    }

    private static let baseURL = "https://img.stripecdn.com/cdn-cgi/image"

    /// The pixels per point to request: the screen's scale, rounded up.
    static var screenDPR: Int {
        #if os(visionOS)
        return 1
        #else
        return Int(UIScreen.main.scale.rounded(.up))
        #endif
    }

    /// Returns a URL that fetches `url` `height` points tall at `dpr` pixels per point, so `height * dpr` pixels tall.
    static func url(for url: URL, format: Format, height: Int, dpr: Int = screenDPR) -> URL {
        // `url` is already percent-encoded, so append it as-is. The proxy takes the rest of the path, including any query, as the source.
        // Safe to force-unwrap: this prefixes a valid URL with a valid path.
        return URL(string: "\(baseURL)/format=\(format.rawValue),height=\(height),dpr=\(dpr)/\(url.absoluteString)")!
    }
}
