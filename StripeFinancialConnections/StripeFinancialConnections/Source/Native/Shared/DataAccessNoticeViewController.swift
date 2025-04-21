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
    private let appearance: FinancialConnectionsAppearance
    private let didSelectUrl: (URL) -> Void

    init(
        dataAccessNotice: FinancialConnectionsDataAccessNotice,
        appearance: FinancialConnectionsAppearance,
        didSelectUrl: @escaping (URL) -> Void
    ) {
        self.dataAccessNotice = dataAccessNotice
        self.appearance = appearance
        self.didSelectUrl = didSelectUrl
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let firstSubtitle: String?
        let contentView: UIView
        if let connectedAccountNotice = dataAccessNotice.connectedAccountNotice {
            firstSubtitle = connectedAccountNotice.subtitle
            contentView = CreateConnectedAccountContentView(
                connectedAccountBulletItems: connectedAccountNotice.body.bullets,
                secondSubtitle: dataAccessNotice.subtitle,
                merchantBulletItems: dataAccessNotice.body.bullets,
                didSelectURL: didSelectUrl
            )
        } else {
            firstSubtitle = dataAccessNotice.subtitle
            contentView = CreateMultiBulletinView(
                bulletItems: dataAccessNotice.body.bullets,
                didSelectURL: didSelectUrl
            )
        }

        setup(
            withContentView: PaneLayoutView.createContentView(
                iconView: RoundedIconView(
                    image: .imageUrl(dataAccessNotice.icon?.default),
                    style: .circle,
                    appearance: appearance
                ),
                title: dataAccessNotice.title,
                subtitle: firstSubtitle,
                contentView: contentView,
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
                appearance: appearance,
                didSelectURL: didSelectUrl
            ).footerView
        )
    }
}

private func CreateConnectedAccountContentView(
    connectedAccountBulletItems: [FinancialConnectionsBulletPoint],
    secondSubtitle: String?,
    merchantBulletItems: [FinancialConnectionsBulletPoint],
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let verticalStackView = HitTestStackView()
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 24
    verticalStackView.addArrangedSubview(
        CreateMultiBulletinView(
            bulletItems: connectedAccountBulletItems,
            didSelectURL: didSelectURL
        )
    )
    if let secondSubtitle = secondSubtitle {
        let secondSubtitleLabel = AttributedTextView(
            font: .body(.medium),
            boldFont: .body(.mediumEmphasized),
            linkFont: .body(.mediumEmphasized),
            textColor: FinancialConnectionsAppearance.Colors.textDefault
        )
        secondSubtitleLabel.setText(secondSubtitle)
        verticalStackView.addArrangedSubview(secondSubtitleLabel)
    }
    verticalStackView.addArrangedSubview(
        CreateMultiBulletinView(
            bulletItems: merchantBulletItems,
            didSelectURL: didSelectURL
        )
    )
    return verticalStackView
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
    imageView.tintColor = FinancialConnectionsAppearance.Colors.icon
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

#if DEBUG

import SwiftUI

private struct DataAccessNoticeViewControllerRepresentable: UIViewControllerRepresentable {
    let dataAccessNotice: FinancialConnectionsDataAccessNotice

    func makeUIViewController(context: Context) -> DataAccessNoticeViewController {
        DataAccessNoticeViewController(
            dataAccessNotice: dataAccessNotice,
            appearance: .stripe,
            didSelectUrl: { _  in })
    }

    func updateUIViewController(
        _ viewController: DataAccessNoticeViewController,
        context: Context
    ) {}
}

struct DataAccessNoticeViewController_Previews: PreviewProvider {
    static var previews: some View {
        DataAccessNoticeViewControllerRepresentable(
            dataAccessNotice: FinancialConnectionsDataAccessNotice(
                icon: FinancialConnectionsImage(
                    default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--platform-stripeBrand-3x.png"
                ),
                title: "Data sharing",
                connectedAccountNotice: nil,
                subtitle: "[Merchant] will have access to the following data and related insights:",
                body: FinancialConnectionsDataAccessNotice.Body(
                    bullets: [
                        FinancialConnectionsBulletPoint(
                            icon: FinancialConnectionsImage(
                                default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--bank-primary-3x.png"
                            ),
                            title: "Account details"
                        ),
                        FinancialConnectionsBulletPoint(
                            icon: FinancialConnectionsImage(
                                default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--balance-primary-3x.png"
                            ),
                            title: "Balances"
                        ),
                    ]
                ),
                disclaimer: "Learn about [data shared with Stripe](https://test.com) and [how to disconnect](https://test.com)",
                cta: "OK"
            )
        )

        DataAccessNoticeViewControllerRepresentable(
            dataAccessNotice: FinancialConnectionsDataAccessNotice(
                icon: FinancialConnectionsImage(
                    default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--platform-stripeBrand-3x.png"
                ),
                title: "Data sharing",
                connectedAccountNotice: FinancialConnectionsDataAccessNotice.ConnectedAccountNotice(
                    subtitle: "[Connected account] will have access to the following data and related insights:",
                    body: FinancialConnectionsDataAccessNotice.Body(
                        bullets: [
                            FinancialConnectionsBulletPoint(
                                icon: FinancialConnectionsImage(
                                    default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--bank-primary-3x.png"
                                ),
                                title: "[C] Account details"
                            ),
                            FinancialConnectionsBulletPoint(
                                icon: FinancialConnectionsImage(
                                    default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--balance-primary-3x.png"
                                ),
                                title: "[C] Balances"
                            ),
                        ]
                    )
                ),
                subtitle: "[Merchant] will have access to the following data and related insights:",
                body: FinancialConnectionsDataAccessNotice.Body(
                    bullets: [
                        FinancialConnectionsBulletPoint(
                            icon: FinancialConnectionsImage(
                                default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--bank-primary-3x.png"
                            ),
                            title: "Account details"
                        ),
                        FinancialConnectionsBulletPoint(
                            icon: FinancialConnectionsImage(
                                default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--balance-primary-3x.png"
                            ),
                            title: "Balances"
                        ),
                    ]
                ),
                disclaimer: "Learn about [data shared with Stripe](https://test.com) and [how to disconnect](https://test.com)",
                cta: "OK"
            )
        )
    }
}

#endif
