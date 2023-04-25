//
//  IdentityUI.swift
//  StripeIdentity
//
//  Created by Jaime Park on 1/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

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
        return UILabel.appearance().textColor ?? .label
    }

    static let iconColor = UIColor.systemGray

    // MARK: Separator

    static let separatorColor = UIColor.separator
    static let separatorHeight: CGFloat = 1

    // MARK: Scanning View

    static let documentCameraPreviewAspectRatio: CGFloat = 1.25  // 5:4
    static let scanningViewLabelMinHeightNumberOfLines: Int = 3
    static let scanningViewLabelBottomPadding: CGFloat = 24

    static let identityElementsUITheme: ElementsUITheme = {
        var identityElementsUITheme = ElementsUITheme.default

        var fonts = ElementsUITheme.Font()
        fonts.subheadline = preferredFont(forTextStyle: .body).withSize(14)
        fonts.subheadlineBold = preferredFont(forTextStyle: .body, weight: .bold).withSize(14)
        fonts.sectionHeader = preferredFont(forTextStyle: .body, weight: .semibold).withSize(13)
        fonts.caption = preferredFont(forTextStyle: .caption1, weight: .regular).withSize(12)
        fonts.footnote = preferredFont(forTextStyle: .footnote, weight: .regular)
        fonts.footnoteEmphasis = preferredFont(forTextStyle: .footnote, weight: .medium)

        identityElementsUITheme.fonts = fonts
        return identityElementsUITheme
    }()
}
