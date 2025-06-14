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

    // MARK: - Corner radii

    static let largeCornerRadius: CGFloat = 24

    static let cornerRadius: CGFloat = 12

    static let mediumCornerRadius: CGFloat = 8

    static let smallCornerRadius: CGFloat = 4

    // MARK: - Border

    static let borderWidth: CGFloat = 1.5

    static let highlightBorderConfiguration = HighlightBorderConfiguration(
        width: borderWidth,
        color: .linkBorderSelected,
        animator: animator
    )

    // MARK: - Buttons

    private static let minimumLabelHeight: CGFloat = 24

    private static let minimumButtonHeight: CGFloat = 44

    static func primaryButtonHeight(margins: NSDirectionalEdgeInsets) -> CGFloat {
        let height = LinkUI.minimumLabelHeight + margins.top + margins.bottom
        return max(height, minimumButtonHeight)
    }

    // MARK: - Margins

    static let buttonMargins: NSDirectionalEdgeInsets = .insets(amount: 16)

    static let compactButtonMargins: NSDirectionalEdgeInsets = .insets(top: 12, leading: 16, bottom: 12, trailing: 16)

    static let contentMargins: NSDirectionalEdgeInsets = .insets(top: 2, leading: 20, bottom: 20, trailing: 20)

    // MARK: - Content spacing

    static let extraLargeContentSpacing: CGFloat = 32

    static let largeContentSpacing: CGFloat = 24

    static let contentSpacing: CGFloat = 16

    static let smallContentSpacing: CGFloat = 8

    static let tinyContentSpacing: CGFloat = 4

    // MARK: - Navigation bar

    static let navigationBarHeight: CGFloat = 70

    static let navigationBarButtonSize: CGFloat = 32

    static let navigationBarButtonContentSize: CGFloat = 12

    // MARK: - Animations

    static let animator: UIViewPropertyAnimator = {
        let params = UISpringTimingParameters(
            mass: 1.0,
            dampingRatio: 0.93,
            frequencyResponse: 0.22
        )
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: params)
        animator.isInterruptible = true
        return animator
    }()
}

// MARK: Development flags

extension LinkUI {

    /// Whether or not the UI can show features that are under development.
    ///
    /// - Note: This flag is meant to be controlled by launch arg.
    static var featurePreview: Bool {
        UserDefaults.standard.bool(forKey: "STPLinkFeaturePreview")
    }

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
            return UIFont.systemFont(ofSize: 24, weight: .semibold).scaled(
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

// MARK: - Appearance

extension LinkUI {

    static let appearance: PaymentSheet.Appearance = {
        var appearance = PaymentSheet.Appearance.default
        appearance.cornerRadius = LinkUI.cornerRadius
        appearance.colors.primary = .linkBorderSelected
        appearance.colors.background = .linkSurfacePrimary

        // Text
        appearance.colors.text = .linkTextPrimary
        appearance.colors.textSecondary = .linkTextSecondary

        // Insets
        appearance.textFieldInsets = NSDirectionalEdgeInsets(
            top: LinkUI.smallContentSpacing,
            leading: LinkUI.contentSpacing,
            bottom: LinkUI.smallContentSpacing,
            trailing: LinkUI.contentSpacing
        )

        // Components
        appearance.colors.componentBorder = .linkSurfacePrimary
        appearance.colors.componentText = .linkTextPrimary
        appearance.colors.componentPlaceholderText = .linkTextSecondary
        appearance.colors.componentBackground = .linkSurfaceSecondary
        appearance.colors.componentBorder = .linkSurfaceSecondary
        appearance.colors.componentDivider = .linkBorderDefault
        appearance.colors.selectedComponentBorder = .linkBorderSelected
        appearance.shadow = .disabled

        // Primary button
        appearance.primaryButton.textColor = .linkContentOnPrimaryButton
        appearance.primaryButton.backgroundColor = .linkButtonBrand
        appearance.primaryButton.successBackgroundColor = .linkButtonBrand
        appearance.primaryButton.borderWidth = 0
        appearance.primaryButton.cornerRadius = LinkUI.cornerRadius
        appearance.primaryButton.font = LinkUI.font(forTextStyle: .bodyEmphasized)

        return appearance
    }()

}
