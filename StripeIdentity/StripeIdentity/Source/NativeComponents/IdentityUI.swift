//
//  IdentityUI.swift
//  StripeIdentity
//
//  Created by Jaime Park on 1/26/22.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// Stores common UI values used throughout Identity
struct IdentityUI {

    // MARK: Font

    static var titleFont: UIFont {
        preferredFont(forTextStyle: .title1, weight: .medium)
    }

    static var instructionsFont: UIFont {
        preferredFont(forTextStyle: .subheadline)
    }

    static func preferredFont(
        forTextStyle style: UIFont.TextStyle,
        weight: UIFont.Weight? = nil
    ) -> UIFont {
        // If app has font set using UIAppearance, use that
        guard let font = UILabel.appearance().font else {
            if let weight = weight {
                return UIFont.preferredFont(forTextStyle: style, weight: weight)
            } else {
                return UIFont.preferredFont(forTextStyle: style)
            }
        }

        return font.withPreferredSize(forTextStyle: style, weight: weight)
    }

    // MARK: Colors

    static let containerColor = UIColor.dynamic(
        light: UIColor(red: 0.969, green: 0.98, blue: 0.988, alpha: 1),
        dark: UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1)
    )

    static let stripeBlurple = UIColor(red: 0.33, green: 0.41, blue: 0.83, alpha: 1)

    static var textColor: UIColor {
        return UILabel.appearance().textColor ?? CompatibleColor.label
    }

    static let iconColor = UIColor.systemGray

    // MARK: Separator

    static let separatorColor = CompatibleColor.separator
    static let separatorHeight: CGFloat = 1
}
