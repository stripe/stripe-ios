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
    public static let contentViewInsets: NSDirectionalEdgeInsets = .insets(top: 4, leading: 11, bottom: 4, trailing: 11)
    public static let fieldBorderColor: UIColor = .systemGray3
    public static let fieldBorderWidth: CGFloat = 1
    public static let textFieldFont: UIFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 14))
    public static let sectionTitleFont: UIFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))
    /// The spacing between elements of a SectionElement
    public static let sectionElementInternalSpacing: CGFloat = 8
    /// The spacing between elements of a FormElement
    public static let formSpacing: CGFloat = 16
    public static let defaultCornerRadius: CGFloat = 6
    public static let backgroundColor: UIColor = {
        // systemBackground has a 'base' and 'elevated' state; we don't want this behavior.
        return .dynamic(light: .systemBackground, dark: .secondarySystemBackground)
    }()

    public static let disabledBackgroundColor: UIColor = {
        return .dynamic(
            light: UIColor(red: 248.0 / 255.0, green: 248.0 / 255.0, blue: 248.0 / 255.0, alpha: 1),
            dark: UIColor(red: 116.0 / 255.0, green: 116.0 / 255.0, blue: 128.0 / 255.0, alpha: 0.18)
        )
    }()

    public static func makeErrorLabel(theme: ElementsAppearance) -> UILabel {
        let label = UILabel()
        label.font = theme.fonts.error
        label.textColor = theme.colors.danger
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }

    public static func makeSmallFootnote(theme: ElementsAppearance) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.font = theme.fonts.smallFootnote
        textView.backgroundColor = .clear
        textView.textColor = theme.colors.secondaryText
        textView.linkTextAttributes = [.foregroundColor: theme.colors.primary]
        textView.isUserInteractionEnabled = false
        return textView
    }

    public static func makeNoticeTextField(theme: ElementsAppearance) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.font = theme.fonts.footnote
        textView.backgroundColor = .clear
        textView.textColor = theme.colors.secondaryText
        textView.linkTextAttributes = [.foregroundColor: theme.colors.primary]
        return textView
    }

    public static func makeSectionTitleLabel(theme: ElementsAppearance) -> UILabel {
        let label = UILabel()
        label.font = theme.fonts.sectionHeader
        label.textColor = theme.colors.secondaryText
        label.accessibilityTraits = [.header]
        return label
    }
}
