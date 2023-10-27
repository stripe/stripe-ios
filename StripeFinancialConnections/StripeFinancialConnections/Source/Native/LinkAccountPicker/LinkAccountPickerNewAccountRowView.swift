//
//  LinkAccountPickerNewAccountRowView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/14/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class LinkAccountPickerNewAccountRowView: UIView {

    private let didSelect: () -> Void

    init(
        title: String,
        imageUrl: String?,
        didSelect: @escaping () -> Void
    ) {
        self.didSelect = didSelect
        super.init(frame: .zero)

        let horizontalStackView = CreateHorizontalStackView()
        if let imageUrl = imageUrl {
            horizontalStackView.addArrangedSubview(
                CreateIconView(imageUrl: imageUrl)
            )
        }
        horizontalStackView.addArrangedSubview(
            CreateTitleLabelView(
                title: title
            )
        )
        addAndPinSubviewToSafeArea(horizontalStackView)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        addGestureRecognizer(tapGestureRecognizer)

        layer.cornerRadius = 8
        layer.borderColor = UIColor.borderNeutral.cgColor
        layer.borderWidth = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapView() {
        self.didSelect()
    }
}

private func CreateIconView(imageUrl: String) -> UIView {
    let diameter: CGFloat = 24
    let iconImageView = UIImageView()
    iconImageView.contentMode = .scaleAspectFit
    iconImageView.setImage(with: imageUrl)
    let paddedView = UIStackView(arrangedSubviews: [iconImageView])
    paddedView.backgroundColor = .textBrand.withAlphaComponent(0.1)
    paddedView.layer.cornerRadius = 6
    paddedView.isLayoutMarginsRelativeArrangement = true
    paddedView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 6,
        leading: 6,
        bottom: 6,
        trailing: 6
    )
    NSLayoutConstraint.activate([
        paddedView.widthAnchor.constraint(equalToConstant: diameter),
        paddedView.heightAnchor.constraint(equalToConstant: diameter),
    ])
    return paddedView
}

private func CreateTitleLabelView(title: String) -> UIView {
    let titleLabel = AttributedLabel(
        font: .label(.largeEmphasized),
        textColor: .textBrand
    )
    titleLabel.text = title
    titleLabel.lineBreakMode = .byCharWrapping
    return titleLabel
}

private func CreateHorizontalStackView() -> UIStackView {
    let horizontalStackView = UIStackView()
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 12
    horizontalStackView.alignment = .center
    horizontalStackView.isLayoutMarginsRelativeArrangement = true
    horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 12,
        leading: 12,
        bottom: 12,
        trailing: 12
    )
    return horizontalStackView
}

#if DEBUG

import SwiftUI

private struct LinkAccountPickerNewAccountRowViewUIViewRepresentable: UIViewRepresentable {

    let title: String
    let imageUrl: String?

    func makeUIView(context: Context) -> LinkAccountPickerNewAccountRowView {
        return LinkAccountPickerNewAccountRowView(
            title: title,
            imageUrl: imageUrl,
            didSelect: {}
        )
    }

    func updateUIView(_ uiView: LinkAccountPickerNewAccountRowView, context: Context) {}
}

struct LinkAccountPickerNewAccountRowView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            ScrollView {
                VStack(spacing: 10) {
                    LinkAccountPickerNewAccountRowViewUIViewRepresentable(
                        title: "New bank account",
                        imageUrl: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--add-purple-3x.png"
                    )
                        .frame(height: 48)

                    LinkAccountPickerNewAccountRowViewUIViewRepresentable(
                        title: "New bank account",
                        imageUrl: nil
                    )
                        .frame(height: 48)
                }
                .padding()
            }
        }
    }
}

#endif
