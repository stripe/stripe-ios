//
//  CardScanButton.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 3/23/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import CloudKit

extension UIButton {
    @available(iOS 13, macCatalyst 14, *)
    static func makeCardScanButton(theme: ElementsUITheme = .default) -> UIButton {
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        let iconConfig = UIImage.SymbolConfiguration(
            font: fontMetrics.scaledFont(for: UIFont.systemFont(ofSize: 9, weight: .semibold))
        )

        let scanButton = UIButton(type: .system)
        scanButton.setTitle(String.Localized.scan_card, for: .normal)
        scanButton.setImage(UIImage(systemName: "camera.fill", withConfiguration: iconConfig), for: .normal)
        scanButton.setContentSpacing(4, withEdgeInsets: .zero)
        scanButton.tintColor = theme.colors.primary
        scanButton.titleLabel?.font = theme.fonts.sectionHeader
        scanButton.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        return scanButton
    }
}
