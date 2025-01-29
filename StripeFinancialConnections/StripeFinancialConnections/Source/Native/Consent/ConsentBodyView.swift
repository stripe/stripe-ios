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

#if DEBUG

import SwiftUI

private struct ConsentBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> ConsentBodyView {
        ConsentBodyView(
            bulletItems: [
                FinancialConnectionsBulletPoint(
                    icon: FinancialConnectionsImage(
                        default:
                            "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--reserve-primary-3x.png"
                    ),
                    content:
                        "Stripe will allow Goldilocks to access only the [data requested](https://www.stripe.com). We never share your login details with them."
                ),
                FinancialConnectionsBulletPoint(
                    icon: FinancialConnectionsImage(
                        default:
                            "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--reserve-primary-3x.png"
                    ),
                    content: "Your data is encrypted for your protection."
                ),
                FinancialConnectionsBulletPoint(
                    icon: FinancialConnectionsImage(
                        default:
                            "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--reserve-primary-3x.png"
                    ),
                    content: "You can [disconnect](https://www.stripe.com) your accounts at any time."
                ),
            ],
            didSelectURL: { _ in }
        )
    }

    func updateUIView(_ uiView: ConsentBodyView, context: Context) {}
}

struct ConsentBodyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            ConsentBodyViewUIViewRepresentable()
                .frame(maxHeight: 200)
                .padding()
            Spacer()
        }
    }
}

#endif
