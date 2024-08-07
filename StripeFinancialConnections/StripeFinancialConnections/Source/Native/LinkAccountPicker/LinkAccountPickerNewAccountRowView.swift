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
        theme: FinancialConnectionsTheme,
        didSelect: @escaping () -> Void
    ) {
        self.didSelect = didSelect
        super.init(frame: .zero)

        let horizontalStackView = CreateHorizontalStackView()
        if let imageUrl = imageUrl {
            horizontalStackView.addArrangedSubview(
                CreateIconView(imageUrl: imageUrl, theme: theme)
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
        layer.borderColor = UIColor.borderDefault.cgColor
        layer.borderWidth = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapView() {
        self.didSelect()
    }
}

private func CreateIconView(imageUrl: String, theme: FinancialConnectionsTheme) -> UIView {
    RoundedIconView(
        image: .imageUrl(imageUrl),
        style: .rounded,
        theme: theme
    )
}

private func CreateTitleLabelView(title: String) -> UIView {
    let titleLabel = AttributedLabel(
        font: .label(.largeEmphasized),
        textColor: .textDefault
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
    let theme: FinancialConnectionsTheme

    func makeUIView(context: Context) -> LinkAccountPickerNewAccountRowView {
        return LinkAccountPickerNewAccountRowView(
            title: title,
            imageUrl: imageUrl,
            theme: theme,
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
                        theme: .light
                    )
                        .frame(height: 88)

                    LinkAccountPickerNewAccountRowViewUIViewRepresentable(
                        title: "New bank account",
                        imageUrl: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--add-purple-3x.png",
                        theme: .linkLight
                    )
                        .frame(height: 88)

                    LinkAccountPickerNewAccountRowViewUIViewRepresentable(
                        title: "New bank account",
                        imageUrl: nil,
                        theme: .light
                    )
                        .frame(height: 88)
                }
                .padding()
            }
        }
    }
}

#endif
