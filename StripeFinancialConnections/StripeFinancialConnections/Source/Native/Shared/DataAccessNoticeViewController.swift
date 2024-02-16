//
//  DataAccessNoticeViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/3/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class DataAccessNoticeViewController: SheetViewController {

    private let dataAccessNotice: FinancialConnectionsDataAccessNotice
    private let didSelectUrl: (URL) -> Void

    init(
        dataAccessNotice: FinancialConnectionsDataAccessNotice,
        didSelectUrl: @escaping (URL) -> Void
    ) {
        self.dataAccessNotice = dataAccessNotice
        self.didSelectUrl = didSelectUrl
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup(
            withContentView: PaneLayoutView.createContentView(
                iconView: RoundedIconView(
                    image: .imageUrl(dataAccessNotice.icon?.default),
                    style: .circle
                ),
                title: dataAccessNotice.title,
                subtitle: dataAccessNotice.subtitle,
                contentView: CreateMultiBulletinView(
                    bulletItems: dataAccessNotice.body.bullets,
                    didSelectURL: didSelectUrl
                ),
                isSheet: true
            ),
            footerView: PaneLayoutView.createFooterView(
                primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: dataAccessNotice.cta,
                    action: { [weak self] in
                        guard let self = self else { return }
                        self.dismiss(animated: true)
                    }
                ),
                secondaryButtonConfiguration: nil,
                topText: dataAccessNotice.disclaimer,
                didSelectURL: didSelectUrl
            ).footerView
        )
    }
}

private func CreateMultiBulletinView(
    bulletItems: [FinancialConnectionsBulletPoint],
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let verticalStackView = HitTestStackView(
        arrangedSubviews: {
            var subviews: [UIView] = []
            bulletItems.forEach { bulletItem in
                subviews.append(
                    CreateSingleBulletinView(
                        title: bulletItem.title,
                        subtitle: bulletItem.content,
                        iconUrl: bulletItem.icon?.default,
                        didSelectURL: didSelectURL
                    )
                )
            }
            return subviews
        }()
    )
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 16
    return verticalStackView
}

private func CreateSingleBulletinView(
    title: String?,
    subtitle: String?,
    iconUrl: String?,
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.tintColor = .iconDefault
    if let iconUrl = iconUrl {
        imageView.setImage(with: iconUrl, useAlwaysTemplateRenderingMode: true)
    } else {
        imageView.image = Image.bullet.makeImage().withRenderingMode(.alwaysTemplate)
    }
    imageView.translatesAutoresizingMaskIntoConstraints = false
    let imageDiameter: CGFloat = 20
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: imageDiameter),
        imageView.heightAnchor.constraint(equalToConstant: imageDiameter),
    ])

    let bulletPointLabelView = BulletPointLabelView(
        title: title,
        content: subtitle,
        didSelectURL: didSelectURL
    )
    let horizontalStackView = HitTestStackView(
        arrangedSubviews: [
            {
                // add padding to the icon so its better aligned with text
                let paddingStackView = UIStackView(arrangedSubviews: [imageView])
                paddingStackView.isLayoutMarginsRelativeArrangement = true
                paddingStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                    // center the image in the middle of the first line height
                    top: max(0, (bulletPointLabelView.topLineHeight - imageDiameter) / 2),
                    leading: 0,
                    bottom: 0,
                    trailing: 0
                )
                return paddingStackView
            }(),
            bulletPointLabelView,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 16
    horizontalStackView.alignment = .top
    return horizontalStackView
}
