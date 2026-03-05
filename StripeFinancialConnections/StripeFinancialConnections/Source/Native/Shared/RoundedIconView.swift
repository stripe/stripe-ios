//
//  RoundedIconView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/29/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class RoundedIconView: UIView {

    enum ImageType {
        /// A local image. Images live in `/Resources/Images`, and defined in `/Source/Helpers/Image.swift`.
        case image(Image)

        /// A remote image from a given URL, and an optional local image to use as a placeholder.
        case imageUrl(String?, placeholder: Image? = nil)
    }

    enum Style {
        case rounded
        case circle
    }

    init(image: ImageType, style: Style, appearance: FinancialConnectionsAppearance) {
        super.init(frame: .zero)
        let diameter: CGFloat = 56
        let cornerRadius: CGFloat
        switch style {
        case .rounded:
            cornerRadius = 12
        case .circle:
            cornerRadius = diameter / 2
        }

        backgroundColor = appearance.colors.iconBackground
        layer.cornerRadius = cornerRadius

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter),
        ])

        let iconImageView = UIImageView()
        iconImageView.tintColor = appearance.colors.iconTint
        switch image {
        case .image(let image):
            iconImageView.image = image.makeImage(template: true)
        case .imageUrl(let imageUrl, let placeholder):
            iconImageView.setImage(
                with: imageUrl,
                placeholder: placeholder?.makeImage(template: true),
                useAlwaysTemplateRenderingMode: true
            )
        }
        addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
