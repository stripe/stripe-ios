//
//  RetrieveAccountsLoadingView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/8/24.
//

import Foundation
import UIKit

final class RetrieveAccountsLoadingView: UIView {

    init(institutionIconUrl: String?) {
        super.init(frame: .zero)
        let paneLayoutView = PaneLayoutView(
            contentView: PaneLayoutView.createContentView(
                iconView: {
                    if let institutionIconUrl = institutionIconUrl {
                        let institutionIconView = InstitutionIconView()
                        institutionIconView.setImageUrl(institutionIconUrl)
                        return institutionIconView
                    } else {
                        return nil
                    }
                }(),
                title: STPLocalizedString(
                    "Retrieving accounts...",
                    "The title of the loading screen that appears when a user just logged into their bank account, and now is waiting for their bank accounts to load. Once the bank accounts are loaded, user will be able to pick the bank account they want to to use for things like payments."
                ),
                subtitle: nil,
                contentView: {
                    let verticalStackView = UIStackView(
                        arrangedSubviews: [
                            ShimmeringAccountPickerRow(),
                            ShimmeringAccountPickerRow(),
                            ShimmeringAccountPickerRow(),
                            ShimmeringAccountPickerRow(),
                        ]
                    )
                    verticalStackView.axis = .vertical
                    verticalStackView.spacing = 16
                    return verticalStackView
                }()
            ),
            footerView: nil
        )
        paneLayoutView.addTo(view: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class ShimmeringAccountPickerRow: ShimmeringView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = 12
        backgroundColor = .backgroundOffset

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 76),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class ShimmeringView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        startShimmering()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startShimmering() {
        self.alpha = 0.30

        UIView.animate(
            withDuration: 1.0,
            delay: 1.0,
            options: [.autoreverse, .repeat, .allowUserInteraction],
            animations: {
                self.alpha = 1.0
            },
            completion: nil
        )
    }

    func stopShimmering() {
        layer.removeAllAnimations()
        self.alpha = 1.0
    }
}
