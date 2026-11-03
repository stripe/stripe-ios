//
//  CardScanButton.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/23/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore
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

    /// A capsule-shaped variant of the card scan button, used when the card scanner opens automatically.
    /// It gives customers a prominent way back into the scanner to fix an incorrect scan or scan a different card.
    static func makeCardScanPillButton(theme: ElementsAppearance = .default, linkAppearance: LinkAppearance? = nil) -> UIButton {
        let scanButton = makeCardScanButton(theme: theme, linkAppearance: linkAppearance)
        let tintColor = linkAppearance?.colors?.primary ?? theme.colors.primary
        scanButton.configuration?.cornerStyle = .capsule
        scanButton.configuration?.background.backgroundColor = tintColor.withAlphaComponent(0.1)
        scanButton.configuration?.contentInsets = .init(top: 6, leading: 10, bottom: 6, trailing: 10)
        scanButton.setContentHuggingPriority(.required, for: .horizontal)
        return scanButton
    }
}
