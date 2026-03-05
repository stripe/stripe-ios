//
//  NetworkingLinkSignupContentView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/24/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class NetworkingLinkSignupBodyView: UIView {

    init(
        bulletPoints: [FinancialConnectionsBulletPoint],
        formView: UIView,
        didSelectURL: @escaping (URL) -> Void
    ) {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateMultipleBulletPointView(
                    bulletPoints: bulletPoints,
                    didSelectURL: didSelectURL
                ),
                formView,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 24
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateMultipleBulletPointView(
    bulletPoints: [FinancialConnectionsBulletPoint],
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let verticalStackView = HitTestStackView()
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 16
    bulletPoints.forEach { bulletPoint in
        let bulletPointView = CreateBulletPointView(
            title: bulletPoint.title,
            content: bulletPoint.content,
            iconUrl: bulletPoint.icon?.default,
            action: didSelectURL
        )
        verticalStackView.addArrangedSubview(bulletPointView)
    }
    return verticalStackView
}

private func CreateBulletPointView(
    title: String?,
    content: String?,
    iconUrl: String?,
    action: @escaping (URL) -> Void
) -> UIView {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.tintColor = FinancialConnectionsAppearance.Colors.icon
    imageView.setImage(with: iconUrl, useAlwaysTemplateRenderingMode: true)
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
                // add extra padding to `imageView` to align
                // the text + image better
                let extraPaddingView = UIStackView(arrangedSubviews: [imageView])
                extraPaddingView.isLayoutMarginsRelativeArrangement = true
                extraPaddingView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                    // center the image in the middle of the first line height
                    top: max(0, (labelView.topLineHeight - imageDiameter) / 2),
                    leading: 0,
                    bottom: 0,
                    trailing: 0
                )
                return extraPaddingView
            }(),
            labelView,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 16
    horizontalStackView.alignment = .top
    return horizontalStackView
}
