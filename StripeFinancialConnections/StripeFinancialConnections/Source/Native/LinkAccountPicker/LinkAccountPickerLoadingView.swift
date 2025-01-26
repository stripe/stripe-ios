//
//  LinkAccountPickerLoadingView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/26/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class LinkAccountPickerLoadingView: ShimmeringView {

    init() {
        super.init(frame: .zero)
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        for _ in 0..<3 {
            let linkAccountRowView = UIView()
            linkAccountRowView.backgroundColor = FinancialConnectionsAppearance.Colors.backgroundSecondary
            linkAccountRowView.layer.cornerRadius = 12
            linkAccountRowView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                linkAccountRowView.heightAnchor.constraint(equalToConstant: 88)
            ])
            verticalStackView.addArrangedSubview(linkAccountRowView)
        }
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
