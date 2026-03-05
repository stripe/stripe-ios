//
//  ConsentBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/15/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class ConsentBodyView: UIView {

    init(
        bulletItems: [FinancialConnectionsBulletPoint],
        didSelectURL: @escaping (URL) -> Void
    ) {
        super.init(frame: .zero)
        backgroundColor = FinancialConnectionsAppearance.Colors.background

        let verticalStackView = HitTestStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 24
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 8,
            bottom: 0,
            trailing: 8
        )
        bulletItems.forEach { bulletItem in
            verticalStackView.addArrangedSubview(
                CreateLabelView(
                    title: bulletItem.title,
                    content: bulletItem.content,
                    iconUrl: bulletItem.icon?.default,
                    action: didSelectURL
                )
            )
        }
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateLabelView(
    title: String?,
    content: String?,
    iconUrl: String?,
    action: @escaping (URL) -> Void
) -> UIView {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.setImage(with: iconUrl, useAlwaysTemplateRenderingMode: true)
    imageView.tintColor = FinancialConnectionsAppearance.Colors.icon
    imageView.translatesAutoresizingMaskIntoConstraints = false
    let imageDiameter: CGFloat = 20
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: imageDiameter),
        imageView.heightAnchor.constraint(equalToConstant: imageDiameter),
    ])

    let labelView = BulletPointLabelView(
        title: title,
        content: content,
        didSelectURL: action
    )

    let horizontalStackView = HitTestStackView(
        arrangedSubviews: [
            {
                // add padding to the `imageView` so the
                // image is aligned with the label
                let paddingStackView = UIStackView(
                    arrangedSubviews: [imageView]
                )
                paddingStackView.isLayoutMarginsRelativeArrangement = true
                paddingStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                    // center the image in the middle of the first line height
                    top: max(0, (labelView.topLineHeight - imageDiameter) / 2),
                    leading: 0,
                    bottom: 0,
                    trailing: 0
                )
                return paddingStackView
            }(),
            labelView,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 16
    horizontalStackView.alignment = .top
    return horizontalStackView
}
