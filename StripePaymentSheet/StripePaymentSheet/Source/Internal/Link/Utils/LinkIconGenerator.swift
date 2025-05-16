//
//  LinkIconGenerator.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 5/15/25.
//

import UIKit

enum LinkIconGenerator {
    private enum Constants {
        static let iconColor: UIColor = .linkIconDefault
        static let backgroundColor: UIColor = .linkIconBackground

        static let defaultIconSize: CGSize = .init(width: 16, height: 16)
        static let defaultBackgroundSize: CGSize = .init(width: 24, height: 24)
        static let cornerRadius: CGFloat = 3.0
    }

    static func cardIcon(
        backgroundSize: CGSize = Constants.defaultBackgroundSize,
        iconSize: CGSize = Constants.defaultIconSize
    ) -> UIImage {
        let icon = PaymentSheetImageLibrary.linkCardIcon()
        return generateImage(for: icon)
    }

    static func bankIcon(
        backgroundSize: CGSize = Constants.defaultBackgroundSize,
        iconSize: CGSize = Constants.defaultIconSize
    ) -> UIImage {
        let icon = PaymentSheetImageLibrary.linkBankIcon()
        return generateImage(for: icon)
    }

    private static func generateImage(
        for icon: UIImage,
        backgroundSize: CGSize = Constants.defaultBackgroundSize,
        iconSize: CGSize = Constants.defaultIconSize
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: backgroundSize)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: backgroundSize)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: Constants.cornerRadius)

            Constants.backgroundColor.setFill()
            path.fill()

            let iconRect = CGRect(
                x: (backgroundSize.width - iconSize.width) / 2,
                y: (backgroundSize.height - iconSize.height) / 2,
                width: iconSize.width,
                height: iconSize.height
            )
            icon.withTintColor(Constants.iconColor).draw(in: iconRect)
        }
    }
}
