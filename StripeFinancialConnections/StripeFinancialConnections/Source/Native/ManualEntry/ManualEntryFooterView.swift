//
//  ManualEntryFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/25/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class ManualEntryFooterView: UIView {

    private let didSelectContinue: () -> Void

    private(set) lazy var continueButton: Button = {
        let continueButton = Button(configuration: .financialConnectionsPrimary)
        continueButton.title = "Continue"  // TODO: replace with String.Localized.continue when we localize
        continueButton.addTarget(self, action: #selector(didSelectContinueButton), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        continueButton.accessibilityIdentifier = "manual_entry_continue_button"
        return continueButton
    }()

    init(didSelectContinue: @escaping () -> Void) {
        self.didSelectContinue = didSelectContinue
        super.init(frame: .zero)

        let verticalStackView = UIStackView(
            arrangedSubviews: [
                continueButton
            ]
        )
        verticalStackView.axis = .vertical
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectContinueButton() {
        didSelectContinue()
    }

    func setIsLoading(_ isLoading: Bool) {
        continueButton.isLoading = isLoading
    }
}
