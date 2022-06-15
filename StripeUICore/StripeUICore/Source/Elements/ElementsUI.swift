//
//  ElementsUI.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

@_spi(STP) public enum ElementsUI {
    
    /// The distances between an Element's content and its containing view
    public static let contentViewInsets: NSDirectionalEdgeInsets = .insets(top: 4, leading: 11, bottom: 4, trailing: 11)
    public static let fieldBorderColor: UIColor = CompatibleColor.systemGray3
    public static let fieldBorderWidth: CGFloat = 1
    public static let textFieldFont: UIFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 14))
    public static let sectionTitleFont: UIFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))
    /// The spacing between elements of a SectionElement
    public static let sectionSpacing: CGFloat = 4
    /// The spacing between elements of a FormElement
    public static let formSpacing: CGFloat = 12
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
        label.font = ElementsUITheme.current.fonts.footnote
        label.textColor = ElementsUITheme.current.colors.danger
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }

    public static func makeNoticeTextField() -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.font = ElementsUITheme.current.fonts.footnote
        textView.backgroundColor = .clear
        textView.textColor = ElementsUITheme.current.colors.secondaryText
        textView.linkTextAttributes = [.foregroundColor: ElementsUITheme.current.colors.primary]
        return textView
    }

    public static func makeSectionTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = ElementsUITheme.current.fonts.sectionHeader
        label.textColor = ElementsUITheme.current.colors.secondaryText
        label.accessibilityTraits = [.header]
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
    public var colors = Color()
    
    public var borderWidth = ElementsUI.fieldBorderWidth
    public var cornerRadius = ElementsUI.defaultCornerRadius
    public var shadow: Shadow? = Shadow()

    public struct Font {
        public init() {}

        public var subheadline = ElementsUI.textFieldFont
        public var subheadlineBold = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 14, weight: .bold))
        public var sectionHeader = ElementsUI.sectionTitleFont
        public var caption = UIFont.systemFont(ofSize: 12, weight: .regular).scaled(
                                            withTextStyle: .caption1,
                                            maximumPointSize: 20)
        public var footnote = UIFont.preferredFont(forTextStyle: .footnote, weight: .regular, maximumPointSize: 20)
        public var footnoteEmphasis = UIFont.preferredFont(forTextStyle: .footnote, weight: .medium, maximumPointSize: 20)
    }

    public struct Color {
        public init() {}

        public var primary = UIColor.systemBlue
        public var parentBackground = CompatibleColor.systemBackground
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

    /// Executes code using the Elements theme as current theme.
    ///
    /// The method temporarily replaces the current theme and executes the actions. After the actions block
    /// finishes, the method will restore the original theme.
    ///
    /// The behavior of this method is similar to `UITraitCollection.performAsCurrent(_:)`.
    ///
    /// - Parameter actions: A block containing code to be executed.
    public func performAsCurrent(_ actions: () -> Void) {
        // Remember previous theme
        let previous = ElementsUITheme.current

        // Set as current theme and perform actions
        ElementsUITheme.current = self
        actions()

        // Restore previous theme
        ElementsUITheme.current = previous
    }
}
