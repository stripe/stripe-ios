//
//  CardScanButton.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/23/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension UIButton {
    static func makeCardScanButton(theme: ElementsAppearance = .default, linkAppearance: LinkAppearance? = nil) -> UIButton {
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        let iconConfig = UIImage.SymbolConfiguration(
            font: fontMetrics.scaledFont(for: UIFont.systemFont(ofSize: 9, weight: .semibold))
        )

        let image: UIImage? = switch theme.iconStyle {
        case .filled:
            UIImage(systemName: "camera.fill", withConfiguration: iconConfig)
        case .outlined:
            UIImage(systemName: "camera", withConfiguration: iconConfig)
        }

        let tintColor = linkAppearance?.colors?.primary ?? theme.colors.primary

        var config = UIButton.Configuration.plain()
        config.image = image
        config.title = String.Localized.scan_card
        config.imagePadding = 4
        config.contentInsets = .zero
        config.titleTextAttributesTransformer = .init { container in
            var container = container
            container.font = theme.fonts.sectionHeader
            return container
        }
        config.baseForegroundColor = tintColor

        let scanButton = UIButton(configuration: config)
        scanButton.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        return scanButton
    }
}
