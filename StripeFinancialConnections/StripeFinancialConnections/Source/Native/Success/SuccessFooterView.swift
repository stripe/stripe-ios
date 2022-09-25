//
//  SuccessFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/15/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

final class SuccessFooterView: UIView {
    
    private let didSelectDone: () -> Void
    private let didSelectLinkAnotherAccount: (() -> Void)?
    
    init(
        didSelectDone: @escaping () -> Void,
        didSelectLinkAnotherAccount: (() -> Void)?
    ) {
        self.didSelectDone = didSelectDone
        self.didSelectLinkAnotherAccount = didSelectLinkAnotherAccount
        super.init(frame: .zero)
        
        let footerStackView = UIStackView()
        footerStackView.axis = .vertical
        footerStackView.spacing = 12
        footerStackView.isLayoutMarginsRelativeArrangement = true
        footerStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 20,
            leading: 24,
            bottom: 24,
            trailing: 24
        )

        if didSelectLinkAnotherAccount != nil {
            let linkAnotherAccount = Button(
                configuration: {
                    var linkAnotherAccountButtonConfiguration = Button.Configuration.secondary()
                    linkAnotherAccountButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
                    linkAnotherAccountButtonConfiguration.foregroundColor = .textSecondary
                    linkAnotherAccountButtonConfiguration.backgroundColor = .borderNeutral
                    return linkAnotherAccountButtonConfiguration
                }()
            )
            linkAnotherAccount.title = String.Localized.link_another_account
            linkAnotherAccount.addTarget(self, action: #selector(didSelectLinkAnotherAccountButton), for: .touchUpInside)
            linkAnotherAccount.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                linkAnotherAccount.heightAnchor.constraint(equalToConstant: 56),
            ])
            footerStackView.addArrangedSubview(linkAnotherAccount)
        }

        let doneButton = Button(
            configuration: {
                var doneButtonConfiguration = Button.Configuration.primary()
                doneButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
                doneButtonConfiguration.backgroundColor = .textBrand
                return doneButtonConfiguration
            }()
        )
        doneButton.title = "Done" // TODO(kgaidis): replace with UIButton.doneButtonTitle once the SDK is localized
        doneButton.addTarget(self, action: #selector(didSelectDoneButton), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.heightAnchor.constraint(equalToConstant: 56),
        ])
        footerStackView.addArrangedSubview(doneButton)

        addAndPinSubviewToSafeArea(footerStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didSelectDoneButton() {
        didSelectDone()
    }
    
    @objc private func didSelectLinkAnotherAccountButton() {
        didSelectLinkAnotherAccount?()
    }
}
