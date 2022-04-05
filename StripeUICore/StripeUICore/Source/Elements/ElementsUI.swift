//
//  ElementsUI.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) public enum ElementsUI {
    
    /// The distances between an Element's content and its containing view
    public static let contentViewInsets: NSDirectionalEdgeInsets = .insets(top: 4, leading: 11, bottom: 6, trailing: 14)
    public static let fieldBorderColor: UIColor = CompatibleColor.systemGray3
    public static let fieldBorderWidth: CGFloat = 1
    public static let textFieldFont: UIFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 14))
    public static let sectionTitleFont: UIFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))
    public static let defaultCornerRadius: CGFloat = 6
    public static let backgroundColor: UIColor = {
        // systemBackground has a 'base' and 'elevated' state; we don't want this behavior.
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return CompatibleColor.secondarySystemBackground
                default:
                    return CompatibleColor.systemBackground
                }
            }
        } else {
            return CompatibleColor.systemBackground
        }
    }()

    public static func makeErrorLabel() -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = ElementsUITheme.current.colors.danger
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }
}

/// Describes the appearance of an Element
@_spi(STP) public struct ElementsUITheme {

    /// The default appearance used for Elements
    public static let `default` = ElementsUITheme()
    
    /// The current appearance used for Elements
    public static var current = ElementsUITheme()
    
    public var fonts = Font()
    public var shapes = Shape()
    public var colors = Color()

    public struct Font {
        public init() {}

        public var subheadline = ElementsUI.textFieldFont
        public var subheadlineBold = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 14, weight: .bold))
        public var sectionHeader = ElementsUI.sectionTitleFont
        public var caption = UIFont.systemFont(ofSize: 12, weight: .regular).scaled(
                                            withTextStyle: .caption1,
                                            maximumPointSize: 20)

    }

    public struct Shape {
        public init() {}

        public var borderWidth = ElementsUI.fieldBorderWidth
        public var cornerRadius = ElementsUI.defaultCornerRadius
        public var shadow: Shadow = Shadow()
    }

    public struct Color {
        public init() {}

        public var primary = UIColor.systemBlue
        public var background = ElementsUI.backgroundColor
        public var border = ElementsUI.fieldBorderColor
        public var divider = ElementsUI.fieldBorderColor
        public var textFieldText = CompatibleColor.label
        public var bodyText = CompatibleColor.label
        public var secondaryText = CompatibleColor.secondaryLabel
        public var placeholderText = CompatibleColor.secondaryLabel
        public var danger = UIColor.systemRed
    }

    public struct Shadow {

        public var color = UIColor.black
        public var alpha = Float(0.05)
        public var offset = CGSize(width: 0, height: 2)
        public var radius = CGFloat(4)

        init () {}

        public init(color: UIColor, alpha: Float, offset: CGSize) {
            self.color = color
            self.alpha = alpha
            self.offset = offset
        }
    }
}
