//
//  SuccessFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/15/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class SuccessFooterView: UIView {

    private let appearance: FinancialConnectionsAppearance
    private let didSelectDone: (SuccessFooterView) -> Void

    private lazy var doneButton: Button = {
        let doneButton = Button.primary(appearance: appearance)
        doneButton.title = "Done"  // TODO: replace with UIButton.doneButtonTitle once the SDK is localized
        doneButton.addTarget(self, action: #selector(didSelectDoneButton), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        doneButton.accessibilityIdentifier = "success_done_button"
        return doneButton
    }()

    init(
        appearance: FinancialConnectionsAppearance,
        didSelectDone: @escaping (SuccessFooterView) -> Void
    ) {
        self.appearance = appearance
        self.didSelectDone = didSelectDone
        super.init(frame: .zero)

        let paddingStackView = UIStackView()
        paddingStackView.axis = .vertical
        paddingStackView.addArrangedSubview(doneButton)
        paddingStackView.isLayoutMarginsRelativeArrangement = true
        paddingStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: 24,
            bottom: 16,
            trailing: 24
        )
        addAndPinSubviewToSafeArea(paddingStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectDoneButton() {
        didSelectDone(self)
    }

    func setIsLoading(_ isLoading: Bool) {
        doneButton.isLoading = isLoading
    }
}
