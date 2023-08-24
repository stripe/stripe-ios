//
//  LinkUI.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
@_spi(STP) import StripeUICore
import UIKit

enum LinkUI {

    /// Semantic text styles for the Link user interface.
    enum TextStyle {
        case title
        case body
        case bodyEmphasized
        case detail
        case detailEmphasized
        case caption
        case captionEmphasized
    }

    static let accountLookupDebounceTime: DispatchTimeInterval = .milliseconds(900)
}

// MARK: - Typography

extension LinkUI {

    /// Returns the font to use for the specified text style.
    ///
    /// If `traitCollection` is provided, the font will be automatically to match the trait collection.
    ///
    /// - Parameters:
    ///   - textStyle: The text style.
    ///   - maximumPointSize: The maximum size that the font can scale up to.
    ///   - traitCollection: Trait collection that the font should be compatible with.
    /// - Returns: Font.
    static func font(
        forTextStyle textStyle: TextStyle,
        maximumPointSize: CGFloat? = nil,
        compatibleWith traitCollection: UITraitCollection? = nil
    ) -> UIFont {
        switch textStyle {
        case .title:
            return UIFont.systemFont(ofSize: 24, weight: .bold).scaled(
                withTextStyle: .headline,
                maximumPointSize: maximumPointSize,
                compatibleWith: traitCollection
            )

        case .body:
            return UIFont.systemFont(ofSize: 16, weight: .regular).scaled(
                withTextStyle: .body,
                maximumPointSize: maximumPointSize,
                compatibleWith: traitCollection
            )

        case .bodyEmphasized:
            return UIFont.systemFont(ofSize: 16, weight: .semibold).scaled(
                withTextStyle: .body,
                maximumPointSize: maximumPointSize,
                compatibleWith: traitCollection
            )

        case .detail:
            return UIFont.systemFont(ofSize: 14, weight: .regular).scaled(
                withTextStyle: .callout,
                maximumPointSize: maximumPointSize,
                compatibleWith: traitCollection
            )

        case .detailEmphasized:
            return UIFont.systemFont(ofSize: 14, weight: .semibold).scaled(
                withTextStyle: .callout,
                maximumPointSize: maximumPointSize,
                compatibleWith: traitCollection
            )

        case .caption:
            return UIFont.systemFont(ofSize: 12, weight: .regular).scaled(
                withTextStyle: .caption1,
                maximumPointSize: maximumPointSize,
                compatibleWith: traitCollection
            )

        case .captionEmphasized:
            return UIFont.systemFont(ofSize: 12, weight: .semibold).scaled(
                withTextStyle: .caption1,
                maximumPointSize: maximumPointSize,
                compatibleWith: traitCollection
            )
        }
    }

    static func lineSpacing(fromRelativeHeight lineHeight: CGFloat, textStyle: TextStyle) -> CGFloat {
        let font = self.font(forTextStyle: textStyle)
        return (font.pointSize * lineHeight) - font.pointSize
    }

}
