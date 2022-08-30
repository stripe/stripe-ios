//
//  ManualEntrySuccessViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/29/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

protocol ManualEntrySuccessViewControllerDelegate: AnyObject {
    func manualEntrySuccessViewControllerDidFinish(_ viewController: ManualEntrySuccessViewController)
}

final class ManualEntrySuccessViewController: UIViewController {
    
    private let microdepositVerificationMethod: MicrodepositVerificationMethod
    private let accountNumberLast4: String
    
    weak var delegate: ManualEntrySuccessViewControllerDelegate?
    
    init(
        microdepositVerificationMethod: MicrodepositVerificationMethod,
        accountNumberLast4: String
    ) {
        self.microdepositVerificationMethod = microdepositVerificationMethod
        self.accountNumberLast4 = accountNumberLast4
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor
        
        let contentViewPair = CreateContentView(
            headerView: CreateHeaderView(
                microdepositVerificationMethod: microdepositVerificationMethod,
                accountNumberLast4: accountNumberLast4
            ),
            transactionTableView: ManualEntrySuccessTransactionTableView(
                microdepositVerificationMethod: microdepositVerificationMethod,
                accountNumberLast4: accountNumberLast4
            )
        )
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                contentViewPair.scrollView,
                CreateFooterView(self),
            ]
        )
        verticalStackView.spacing = 0
        verticalStackView.axis = .vertical
        view.addAndPinSubviewToSafeArea(verticalStackView)
        
        // ensure that content ScrollView is bound to view's width
        contentViewPair.scrollViewContent.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
    }
    
    @objc fileprivate func didSelectDone() {
        delegate?.manualEntrySuccessViewControllerDidFinish(self)
    }
}

// MARK: - Helpers

private func CreateContentView(
    headerView: UIView,
    transactionTableView: UIView
) -> (scrollView: UIScrollView, scrollViewContent: UIView) {
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            headerView,
            transactionTableView,
        ]
    )
    verticalStackView.axis = .vertical
    verticalStackView.isLayoutMarginsRelativeArrangement = true
    verticalStackView.spacing = 24
    verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 16,
        leading: 24,
        bottom: 16,
        trailing: 24
    )
    
    let scrollView = UIScrollView()
    scrollView.keyboardDismissMode = .onDrag
    scrollView.addAndPinSubview(verticalStackView)
    
    return (scrollView, verticalStackView)
}

private func CreateHeaderView(
    microdepositVerificationMethod: FinancialConnectionsPaymentAccountResource.MicrodepositVerificationMethod,
    accountNumberLast4: String
) -> UIView {
    let headerStackView = UIStackView(
        arrangedSubviews: [
            CreateIconView(),
            CreateTitleAndSubtitleView(
                title: "Micro-deposits initiated", //STPLocalizedString("Enter bank account details", "The title of a screen that allows a user to manually enter their bank account information."),
                subtitle: {
                    let subtitle: String
                    if microdepositVerificationMethod == .descriptorCode {
                        subtitle = "Expect a $0.01 deposit to the account ending in ****\(accountNumberLast4) in 1-2 business days and an email with additional instructions to verify your bank account."
                    } else {
                        subtitle = "Expect two small deposits to the account ending in ••••\(accountNumberLast4) in 1-2 business days and an email with additional instructions to verify your bank account."
                    }
                    //STPLocalizedString("Your bank information will be verified with micro-deposits to your account", "The subtitle/description in a screen that allows a user to manually enter their bank account information. It informs the user that their bank account information will have to be verified.")
                    return subtitle
                }()
            ),
        ]
    )
    headerStackView.axis = .vertical
    headerStackView.spacing = 16
    headerStackView.alignment = .leading
    return headerStackView
}

private func CreateIconView() -> UIView {
    let iconContainerView = UIView()
    iconContainerView.backgroundColor = .green
    iconContainerView.layer.cornerRadius = 20 // TODO(kgaidis): fix temporary "icon" styling before we get loading icons
    iconContainerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        iconContainerView.widthAnchor.constraint(equalToConstant: 40),
        iconContainerView.heightAnchor.constraint(equalToConstant: 40),
    ])
    return iconContainerView
}

private func CreateTitleAndSubtitleView(title: String, subtitle: String) -> UIView {
    let titleLabel = UILabel()
    titleLabel.font = .stripeFont(forTextStyle: .subtitle)
    titleLabel.textColor = .textPrimary
    titleLabel.numberOfLines = 0
    titleLabel.text = title
    let subtitleLabel = UILabel()
    subtitleLabel.font = .stripeFont(forTextStyle: .body)
    subtitleLabel.textColor = .textSecondary
    subtitleLabel.numberOfLines = 0
    subtitleLabel.text = subtitle
    let labelStackView = UIStackView(arrangedSubviews: [
        titleLabel,
        subtitleLabel,
    ])
    labelStackView.axis = .vertical
    labelStackView.spacing = 8
    return labelStackView
}

private func CreateFooterView(_ buttonTarget: ManualEntrySuccessViewController) -> UIView {
    let doneButton = Button(
        configuration: {
            var doneButtonConfiguration = Button.Configuration.primary()
            doneButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
            doneButtonConfiguration.backgroundColor = .textBrand
            return doneButtonConfiguration
        }()
    )
    doneButton.title = "Done" // TODO(kgaidis): replace with String.Localized.continue when we localize
    doneButton.addTarget(
        buttonTarget,
        action: #selector(ManualEntrySuccessViewController.didSelectDone),
        for: .touchUpInside
    )
    doneButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        doneButton.heightAnchor.constraint(equalToConstant: 56),
    ])
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            doneButton,
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
    return verticalStackView
}
