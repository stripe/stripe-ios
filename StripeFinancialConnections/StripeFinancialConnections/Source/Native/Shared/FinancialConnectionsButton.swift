//
//  FinancialConnectionsButton.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/8/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

enum FinancialConnectionsButtonConfiguration {
    case primary
    case secondary
}

func FinancialConnectionsButton(configuration: FinancialConnectionsButtonConfiguration) -> StripeUICore.Button {
    let button: Button
    switch configuration {
    case .primary:
        button = Button(configuration: .financialConnectionsPrimary)
    case .secondary:
        button = Button(configuration: .financialConnectionsSecondary)
    }
    // TODO(kgaidis): add shadows
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        button.heightAnchor.constraint(equalToConstant: 56)
    ])
    return button
}
