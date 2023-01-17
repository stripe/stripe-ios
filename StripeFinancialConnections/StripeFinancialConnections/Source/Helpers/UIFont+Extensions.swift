//
//  UIFont+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/8/22.
//

import Foundation
import UIKit

extension UIFont {

    enum StripeTextStyle {
        case subtitle
        case heading
        case subheading
        case kicker
        case body
        case bodyEmphasized
        case detail
        case detailEmphasized
        // `caption` and `captionTight` are the same
        // except for line height which is not configurable
        // on `UIFont`
        case caption
        case captionEmphasized
        case captionTight
        case captionTightEmphasized
        case monospaced
    }

    static func stripeFont(forTextStyle stripeTextStyle: StripeTextStyle) -> UIFont {
        let font: UIFont
        // Mapped from:
        // - https://developer.apple.com/design/human-interface-guidelines/foundations/typography#specifications
        let appleTextStyle: TextStyle
        switch stripeTextStyle {
        case .subtitle:
            // SF Pro Bold 24/32 700
            font = UIFont.systemFont(ofSize: 24, weight: .bold)
            appleTextStyle = .title2
        case .heading:
            // SF Pro Bold 18/24 700
            font = UIFont.systemFont(ofSize: 18, weight: .bold)
            appleTextStyle = .headline
        case .subheading:
            // SF Pro Semibold 18/24 600
            font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            appleTextStyle = .headline
        case .kicker:
            // SF Pro Semibold 12/20 600 ALL CAPS
            font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            appleTextStyle = .caption1
        case .body:
            // SF Pro Regular 16/24 400
            font = UIFont.systemFont(ofSize: 16, weight: .regular)
            appleTextStyle = .body
        case .bodyEmphasized:
            // SF Pro Regular 16/24 600
            font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            appleTextStyle = .body
        case .detail:
            // SF Pro Regular 14/20 400
            font = UIFont.systemFont(ofSize: 14, weight: .regular)
            appleTextStyle = .footnote
        case .detailEmphasized:
            // SF Pro Regular 14/20 600
            font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            appleTextStyle = .footnote
        case .caption:
            // SF Pro Regular 12/18 400
            font = UIFont.systemFont(ofSize: 12, weight: .regular)
            appleTextStyle = .caption1
        case .captionEmphasized:
            // SF Pro Regular 12/18 600
            font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            appleTextStyle = .caption1
        case .captionTight:
            // SF Pro Regular 12/16 400
            font = UIFont.systemFont(ofSize: 12, weight: .regular)
            appleTextStyle = .caption1
        case .captionTightEmphasized:
            // SF Pro Regular 12/16 600
            font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            appleTextStyle = .caption1
        case .monospaced:
            font = .monospacedSystemFont(ofSize: 16, weight: .bold)
            appleTextStyle = .body
        }
        let metrics = UIFontMetrics(forTextStyle: appleTextStyle)
        let scaledFont = metrics.scaledFont(for: font)
        return scaledFont
    }
}
