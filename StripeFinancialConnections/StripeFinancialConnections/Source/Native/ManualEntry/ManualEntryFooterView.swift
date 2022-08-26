//
//  ManualEntryFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/25/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class ManualEntryFooterView: UIView {
    
    private let didSelectContinue: () -> Void
    
    private(set) lazy var continueButton: Button = {
        let continueButton = Button(
            configuration: {
                var continueButtonConfiguration = Button.Configuration.primary()
                continueButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
                continueButtonConfiguration.backgroundColor = .textBrand
                return continueButtonConfiguration
            }()
        )
        continueButton.title = "Continue" // TODO(kgaidis): replace with String.Localized.continue when we localize
        continueButton.addTarget(target, action: #selector(didSelectContinueButton), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            continueButton.heightAnchor.constraint(equalToConstant: 56),
        ])
        return continueButton
    }()
    
    init(didSelectContinue: @escaping () -> Void) {
        self.didSelectContinue = didSelectContinue
        super.init(frame: .zero)
        
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                continueButton,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 20,
            leading: 24,
            bottom: 20,
            trailing: 24
        )
        addAndPinSubview(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didSelectContinueButton() {
        didSelectContinue()
    }
}
