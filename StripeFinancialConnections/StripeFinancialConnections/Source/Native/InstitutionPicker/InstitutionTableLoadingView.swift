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

    init() {
        super.init(frame: UIScreen.main.bounds)
        backgroundColor = FinancialConnectionsAppearance.Colors.background
        let verticalStackView = UIStackView(
            arrangedSubviews: (0..<10).map({ _ in
                ShimmeringInstitutionRowView()
            })
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 0 // the rows have spacing through padding
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        let horizontalStackView = UIStackView(
            arrangedSubviews: [
                CreateRowIconView(),
                CreateRowMultipleLabelView(),
            ]
        )
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = 12
        horizontalStackView.isLayoutMarginsRelativeArrangement = true
        horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 24,
            bottom: 8,
            trailing: 24
        )
        addAndPinSubview(horizontalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateRowIconView() -> UIView {
    let iconView = UIView()
    iconView.backgroundColor = FinancialConnectionsAppearance.Colors.backgroundSecondary
    iconView.layer.cornerRadius = 12
    iconView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        iconView.heightAnchor.constraint(equalToConstant: 56),
        iconView.widthAnchor.constraint(equalToConstant: 56),
    ])
    return iconView
}

private func CreateRowMultipleLabelView() -> UIView {
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            CreateLabelView(width: 180),
            CreateLabelView(width: 130),
        ]
    )
    verticalStackView.axis = .vertical
    verticalStackView.alignment = .leading
    verticalStackView.spacing = 8
    return verticalStackView
}

private func CreateLabelView(width: CGFloat) -> UIView {
    let labelView = UIView()
    labelView.backgroundColor = FinancialConnectionsAppearance.Colors.backgroundSecondary
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
