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
    /// The distances between a textfield and its containing view
    public static let textfieldInsets: NSDirectionalEdgeInsets = .insets(top: 4, leading: 11, bottom: 6, trailing: 14)
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
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }
}
