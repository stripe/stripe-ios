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
        appearance: FinancialConnectionsAppearance,
        didSelect: @escaping () -> Void
    ) {
        self.didSelect = didSelect
        super.init(frame: .zero)

        let horizontalStackView = CreateHorizontalStackView()
        if let imageUrl = imageUrl {
            horizontalStackView.addArrangedSubview(
                CreateIconView(imageUrl: imageUrl, appearance: appearance)
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

        layer.cornerRadius = 12
        layer.borderColor = FinancialConnectionsAppearance.Colors.borderNeutral.cgColor
        layer.borderWidth = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapView() {
        self.didSelect()
    }

    // CGColor's need to be manually updated when the system theme changes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        layer.borderColor = FinancialConnectionsAppearance.Colors.borderNeutral.cgColor
    }
}

private func CreateIconView(imageUrl: String, appearance: FinancialConnectionsAppearance) -> UIView {
    RoundedIconView(
        image: .imageUrl(imageUrl, placeholder: Image.add),
        style: .rounded,
        appearance: appearance
    )
}

private func CreateTitleLabelView(title: String) -> UIView {
    let titleLabel = AttributedLabel(
        font: .label(.largeEmphasized),
        textColor: FinancialConnectionsAppearance.Colors.textDefault
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
        top: 16,
        leading: 16,
        bottom: 16,
        trailing: 16
    )
    return horizontalStackView
}

#if DEBUG

import SwiftUI

private struct LinkAccountPickerNewAccountRowViewUIViewRepresentable: UIViewRepresentable {

    let title: String
    let imageUrl: String?
    let appearance: FinancialConnectionsAppearance

    func makeUIView(context: Context) -> LinkAccountPickerNewAccountRowView {
        return LinkAccountPickerNewAccountRowView(
            title: title,
            imageUrl: imageUrl,
            appearance: appearance,
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
                        imageUrl: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--add-purple-3x.png",
                        appearance: .stripe
                    )
                        .frame(height: 88)

                    LinkAccountPickerNewAccountRowViewUIViewRepresentable(
                        title: "New bank account",
                        imageUrl: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--add-purple-3x.png",
                        appearance: .link
                    )
                        .frame(height: 88)

                    LinkAccountPickerNewAccountRowViewUIViewRepresentable(
                        title: "New bank account",
                        imageUrl: nil,
                        appearance: .stripe
                    )
                        .frame(height: 88)
                }
                .padding()
            }
        }
    }
}

#endif
