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
        let continueButton = Button.primary()
        continueButton.title = "Submit"  // TODO(kgaidis): localize
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

        let paddingStackView = UIStackView(
            arrangedSubviews: [
                continueButton
            ]
        )
        paddingStackView.isLayoutMarginsRelativeArrangement = true
        paddingStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: 24,
            bottom: 16,
            trailing: 24
        )
        paddingStackView.axis = .vertical
        addAndPinSubview(paddingStackView)
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
