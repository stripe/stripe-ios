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

    private let didSelectDone: (SuccessFooterView) -> Void
    private let didSelectLinkAnotherAccount: (() -> Void)?

    private lazy var doneButton: Button = {
        let doneButton = Button(configuration: .financialConnectionsPrimary)
        doneButton.title = "Done"  // TODO: replace with UIButton.doneButtonTitle once the SDK is localized
        doneButton.addTarget(self, action: #selector(didSelectDoneButton), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        return doneButton
    }()

    init(
        didSelectDone: @escaping (SuccessFooterView) -> Void,
        didSelectLinkAnotherAccount: (() -> Void)?
    ) {
        self.didSelectDone = didSelectDone
        self.didSelectLinkAnotherAccount = didSelectLinkAnotherAccount
        super.init(frame: .zero)

        let footerStackView = UIStackView()
        footerStackView.axis = .vertical
        footerStackView.spacing = 12

        if didSelectLinkAnotherAccount != nil {
            let linkAnotherAccount = Button(configuration: .financialConnectionsSecondary)
            linkAnotherAccount.title = String.Localized.link_another_account
            linkAnotherAccount.addTarget(
                self,
                action: #selector(didSelectLinkAnotherAccountButton),
                for: .touchUpInside
            )
            linkAnotherAccount.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                linkAnotherAccount.heightAnchor.constraint(equalToConstant: 56)
            ])
            footerStackView.addArrangedSubview(linkAnotherAccount)
        }

        footerStackView.addArrangedSubview(doneButton)

        addAndPinSubviewToSafeArea(footerStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectDoneButton() {
        didSelectDone(self)
    }

    @objc private func didSelectLinkAnotherAccountButton() {
        didSelectLinkAnotherAccount?()
    }

    func setIsLoading(_ isLoading: Bool) {
        doneButton.isLoading = isLoading
    }
}
