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

    init(didSelect: @escaping () -> Void) {
        self.didSelect = didSelect
        super.init(frame: .zero)

        let horizontalStackView = CreateHorizontalStackView(
            arrangedSubviews: [
                CreateIconView(),
                CreateTitleLabelView(),
            ]
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

private func CreateIconView() -> UIView {
    let diameter: CGFloat = 24
    let iconImageView = UIImageView()
    iconImageView.contentMode = .scaleAspectFit
    iconImageView.image = Image.add.makeImage()
        .withTintColor(.textBrand, renderingMode: .alwaysOriginal)
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

private func CreateTitleLabelView() -> UIView {
    let titleLabel = AttributedLabel(
        font: .label(.largeEmphasized),
        textColor: .textBrand
    )
    titleLabel.text = STPLocalizedString(
        "New bank account",
        "A button that allows users to add an additional bank account for future payments."
    )
    titleLabel.lineBreakMode = .byCharWrapping
    return titleLabel
}

private func CreateHorizontalStackView(arrangedSubviews: [UIView]) -> UIStackView {
    let horizontalStackView = UIStackView(arrangedSubviews: arrangedSubviews)
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

@available(iOSApplicationExtension, unavailable)
private struct LinkAccountPickerNewAccountRowViewUIViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> LinkAccountPickerNewAccountRowView {
        return LinkAccountPickerNewAccountRowView(didSelect: {})
    }

    func updateUIView(_ uiView: LinkAccountPickerNewAccountRowView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct LinkAccountPickerNewAccountRowView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            ScrollView {
                VStack(spacing: 10) {
                    LinkAccountPickerNewAccountRowViewUIViewRepresentable()
                        .frame(height: 48)
                }
                .padding()
            }
        }
    }
}

#endif
