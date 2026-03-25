//
//  UIButton+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by George Birch on 11/24/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension UIButton {

    static let glassButtonSize: CGFloat = 44

    static func createPlainCloseButton() -> UIButton {
        let button = SheetNavigationButton(type: .custom)
        let image = Image.icon_x_standalone.makeImage(template: true)
        button.setImage(image, for: .normal)

        button.accessibilityLabel = String.Localized.close
        button.accessibilityIdentifier = "UIButton.Close"

        return button
    }

    static func createGlassCloseButton() -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: glassButtonSize, height: glassButtonSize)
        button.widthAnchor.constraint(equalToConstant: glassButtonSize).isActive = true
        button.heightAnchor.constraint(equalToConstant: glassButtonSize).isActive = true

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let image = UIImage(systemName: "xmark", withConfiguration: config)

        button.setImage(image, for: .normal)

        button.accessibilityLabel = String.Localized.close
        button.accessibilityIdentifier = "UIButton.Close"
        button.ios26_applyGlassConfiguration()

        return button
    }
}
