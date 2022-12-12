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
    public static let fieldBorderColor: UIColor = .systemGray3
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
        return .dynamic(light: .systemBackground, dark: .secondarySystemBackground)
    }()

    public static func makeErrorLabel(theme: ElementsUITheme = .default) -> UILabel {
        let label = UILabel()
        label.font = theme.fonts.footnote
        label.textColor = theme.colors.danger
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }

    public static func makeNoticeTextField(theme: ElementsUITheme = .default) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.font = theme.fonts.footnote
        textView.backgroundColor = .clear
        textView.textColor = theme.colors.secondaryText
        textView.linkTextAttributes = [.foregroundColor: theme.colors.primary]
        return textView
    }

    public static func makeSectionTitleLabel(theme: ElementsUITheme = .default) -> UILabel {
        let label = UILabel()
        label.font = theme.fonts.sectionHeader
        label.textColor = theme.colors.secondaryText
        label.accessibilityTraits = [.header]
        return label
    }
}

/// Describes the appearance of an Element
@_spi(STP) public struct ElementsUITheme {

    /// The default appearance used for Elements
    public static let `default` = ElementsUITheme()
    
    public var fonts = Font()
    public var colors = Color()
    
    public var borderWidth = ElementsUI.fieldBorderWidth
    public var cornerRadius = ElementsUI.defaultCornerRadius
    public var shadow: Shadow? = Shadow()

    /// Checks if the theme is bright.
    public var isBright: Bool { colors.background.isBright }

    /// Checks if the theme is dark.
    public var isDark: Bool { !isBright }

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
        public var parentBackground = UIColor.systemBackground
        public var background = ElementsUI.backgroundColor
        public var border = ElementsUI.fieldBorderColor
        public var divider = ElementsUI.fieldBorderColor
        public var textFieldText = UIColor.label
        public var bodyText = UIColor.label
        public var secondaryText = UIColor.secondaryLabel
        public var placeholderText = UIColor.secondaryLabel
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
}
