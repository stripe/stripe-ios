//
//  InstitutionTableLoadingView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/24/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class InstitutionTableLoadingView: UIView {

    init(appearance: FinancialConnectionsAppearance = .stripe) {
        super.init(frame: UIScreen.main.bounds)
        backgroundColor = FinancialConnectionsAppearance.Colors.background
        let verticalStackView = UIStackView(
            arrangedSubviews: (0..<10).map({ _ in
                ShimmeringInstitutionRowView(appearance: appearance)
            })
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 0 // the rows have spacing through padding
        if appearance.colors == .link {
            verticalStackView.backgroundColor = appearance.colors.iconBackground
            verticalStackView.layer.cornerRadius = 12
            verticalStackView.layer.masksToBounds = true
        }
        addSubview(verticalStackView)
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: topAnchor),
            verticalStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            // height will be automatically determined by the UIStackView and it will be clipped beyond the frame
        ])
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class ShimmeringInstitutionRowView: ShimmeringView {

    init(appearance: FinancialConnectionsAppearance) {
        super.init(frame: .zero)
        backgroundColor = .clear

        let placeholderColor = appearance.colors == .link
            ? FinancialConnectionsAppearance.Colors.iconBackgroundOnCard
            : FinancialConnectionsAppearance.Colors.backgroundSecondary
        let horizontalStackView = UIStackView(
            arrangedSubviews: [
                CreateRowIconView(backgroundColor: placeholderColor),
                CreateRowMultipleLabelView(backgroundColor: placeholderColor),
            ]
        )
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = 12
        horizontalStackView.isLayoutMarginsRelativeArrangement = true
        let horizontalMargin: CGFloat = appearance.colors == .link ? 16 : 24
        horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: horizontalMargin,
            bottom: 8,
            trailing: horizontalMargin
        )
        addAndPinSubview(horizontalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateRowIconView(backgroundColor: UIColor) -> UIView {
    let iconView = UIView()
    iconView.backgroundColor = backgroundColor
    iconView.layer.cornerRadius = 12
    iconView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        iconView.heightAnchor.constraint(equalToConstant: 44),
        iconView.widthAnchor.constraint(equalToConstant: 44),
    ])
    return iconView
}

private func CreateRowMultipleLabelView(backgroundColor: UIColor) -> UIView {
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            CreateLabelView(width: 180, backgroundColor: backgroundColor),
            CreateLabelView(width: 130, backgroundColor: backgroundColor),
        ]
    )
    verticalStackView.axis = .vertical
    verticalStackView.alignment = .leading
    verticalStackView.spacing = 8
    return verticalStackView
}

private func CreateLabelView(width: CGFloat, backgroundColor: UIColor) -> UIView {
    let labelView = UIView()
    labelView.backgroundColor = backgroundColor
    labelView.layer.cornerRadius = 8
    labelView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        labelView.widthAnchor.constraint(equalToConstant: width),
        labelView.heightAnchor.constraint(equalToConstant: 16),
    ])
    return labelView
}

#if DEBUG

import SwiftUI

private struct InstitutionTableLoadingViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> InstitutionTableLoadingView {
        InstitutionTableLoadingView()
    }

    func updateUIView(
        _ institutionTableLoadingView: InstitutionTableLoadingView,
        context: Context
    ) {}
}

struct InstitutionTableLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        InstitutionTableLoadingViewUIViewRepresentable()
    }
}

#endif
