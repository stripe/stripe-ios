//
//  ContinueStateView.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 10/5/22.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class ContinueStateView: UIView {

    // MARK: - Properties

    private let didSelectContinue: () -> Void

    // MARK: - UIView

    init(
        institutionImageUrl: String?,
        didSelectContinue: @escaping () -> Void
    ) {
        self.didSelectContinue = didSelectContinue
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor

        let paneLayoutView = PaneWithHeaderLayoutView(
            icon: .view(
                {
                    let institutionIconView = InstitutionIconView(size: .large)
                    institutionIconView.setImageUrl(institutionImageUrl)
                    return institutionIconView
                }()
            ),
            title: STPLocalizedString(
                "Continue linking your account",
                "Title for a label of a screen telling users to tap below to continue linking process."
            ),
            subtitle: STPLocalizedString(
                "You haven't finished linking your account. Press continue to finish the process.",
                "Title for a label explaining that the linking process hasn't finished yet."
            ),
            contentView: {
                let clearView = UIView()
                clearView.backgroundColor = .clear
                return clearView
            }(),
            footerView: CreateFooterView(
                view: self
            )
        )
        paneLayoutView.addTo(view: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func didSelectContinueButton() {
        didSelectContinue()
    }
}

private func CreateFooterView(
    view: ContinueStateView
) -> UIView {
    let continueButton = Button(configuration: .financialConnectionsPrimary)
    continueButton.title = "Continue"  // TODO: when Financial Connections starts supporting localization, change this to `String.Localized.continue`
    continueButton.addTarget(view, action: #selector(ContinueStateView.didSelectContinueButton), for: .touchUpInside)
    continueButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        continueButton.heightAnchor.constraint(equalToConstant: 56)
    ])

    let footerStackView = UIStackView()
    footerStackView.axis = .vertical
    footerStackView.spacing = 20
    footerStackView.addArrangedSubview(continueButton)

    return footerStackView
}
