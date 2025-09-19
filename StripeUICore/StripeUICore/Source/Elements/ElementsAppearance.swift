//
//  ElementsAppearance.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 9/19/25.
//
import UIKit
@_spi(STP) import StripeCore

/// Describes the appearance of an Element
/// A superset of `StripePaymentSheet.PaymentSheetAppearance`. This exists b/c we can't see that type from `StripeUICore`, and we don't want to the public StripePaymentSheet API to be a typealias of this.
@_spi(STP) public struct ElementsAppearance {

    /// The default appearance used for Elements
    public static let `default` = ElementsAppearance()

    public var fonts = Font()
    public var colors = Color()

    /// The thickness of divider lines between elements in a section uses `borderWidth` for consistency, with a minimum thickness of 0.5.
    public var separatorWidth: CGFloat {
        borderWidth > 0 ? borderWidth : 0.5
    }
    public var borderWidth = ElementsUI.fieldBorderWidth
    public var cornerRadius: CGFloat? = ElementsUI.defaultCornerRadius
    public var shadow: Shadow? = Shadow()
    public var textFieldInsets = ElementsUI.contentViewInsets
    public var iconStyle: IconStyle = .filled

    /// The spacing between sections in forms
    public var sectionSpacing = ElementsUI.formSpacing

    public struct Font {
        public init() {}

        public var subheadline = ElementsUI.textFieldFont
        public var subheadlineBold = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 14, weight: .bold))
        public var sectionHeader = ElementsUI.sectionTitleFont
        public var caption = UIFont.systemFont(ofSize: 12, weight: .regular).scaled(
            withTextStyle: .caption1,
            maximumPointSize: 20
        )
        public var footnote = UIFont.preferredFont(forTextStyle: .footnote, weight: .regular, maximumPointSize: 20)
        public var error = UIFont.preferredFont(forTextStyle: .caption2, weight: .regular)
        public var smallFootnote = UIFont.preferredFont(forTextStyle: .caption2, weight: .medium)
        public var footnoteEmphasis = UIFont.preferredFont(forTextStyle: .footnote, weight: .medium, maximumPointSize: 20)
    }

    public struct Color {
        public init() {}

        public var primary = UIColor.systemBlue
        public var parentBackground = UIColor.systemBackground
        public var componentBackground = ElementsUI.backgroundColor
        public var disabledBackground = ElementsUI.disabledBackgroundColor
        public var border = ElementsUI.fieldBorderColor
        public var divider = ElementsUI.fieldBorderColor
        public var textFieldText = UIColor.label
        public var bodyText = UIColor.label
        public var secondaryText = UIColor.secondaryLabel
        public var placeholderText = UIColor.secondaryLabel
        public var danger = UIColor.systemRed

        public var readonlyComponentBackground: UIColor {
            let backgroundColor = parentBackground
            return UIColor(dynamicProvider: { traitCollection in
                let resolvedColor = componentBackground.resolvedColor(with: traitCollection)
                if resolvedColor.isBright {
                    // The brighter the background color, the less we need to darken the color in order to ensure it looks disabled _and_ has enough contrast.
                    // There's undoubtedly a better formula, but I just want:
                    // 0.04 when brightness is 1
                    // 0.09 when brightness is 0.96
                    // and some linear interpolation between:
                    let darkenFactor = -1.25 * backgroundColor.brightness + 1.29
                    return resolvedColor.darken(by: darkenFactor)
                } else {
                    return resolvedColor.lighten(by: 0.01)
                }
            })
        }

    }

    public struct Shadow {

        public var color = UIColor.black
        public var opacity = CGFloat(0.05)
        public var offset = CGSize(width: 0, height: 2)
        public var radius = CGFloat(4)

        init () {}

        public init(color: UIColor, opacity: CGFloat, offset: CGSize, radius: CGFloat) {
            self.color = color
            self.opacity = opacity
            self.offset = offset
            self.radius = radius
        }
    }

    @frozen public enum IconStyle {
        case filled
        case outlined
    }
}
