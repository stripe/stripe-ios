//
//  ManualEntryViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/23/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

protocol ManualEntryViewControllerDelegate: AnyObject {
    func manualEntryViewControllerDidRequestToContinue(_ viewController: ManualEntryViewController)
}

final class ManualEntryViewController: UIViewController {

    private let dataSource: ManualEntryDataSource
    weak var delegate: ManualEntryViewControllerDelegate? = nil
    
    private lazy var manualEntryFormView: ManualEntryFormView = {
        let manualEntryFormView = ManualEntryFormView()
        manualEntryFormView.delegate = self
        return manualEntryFormView
    }()
    private lazy var footerView: ManualEntryFooterView = {
        let manualEntryFooterView = ManualEntryFooterView(
            didSelectContinue: { [weak self] in
                self?.didSelectContinue()
            }
        )
        return manualEntryFooterView
    }()
    
    init(dataSource: ManualEntryDataSource) {
        self.dataSource = dataSource
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
                title: "Enter bank account details",
                subtitle: "Your bank information will be verified with micro-deposits to your account"
            ),
            formView: manualEntryFormView
        )
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                contentViewPair.scrollView,
                footerView,
            ]
        )
        verticalStackView.spacing = 0
        verticalStackView.axis = .vertical
        view.addAndPinSubviewToSafeArea(verticalStackView)
        
        // ensure that content ScrollView is bound to view's width
        contentViewPair.scrollViewContent.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
        
        adjustContinueButtonStateIfNeeded()
    }
    
    private func didSelectContinue() {
        // dataSource.attachBankAccountToLinkAccountSession(routingNumber: <#T##String#>, accountNumber: <#T##String#>
    }
    
    private func adjustContinueButtonStateIfNeeded() {
        footerView.continueButton.isEnabled = (manualEntryFormView.routingAndAccountNumber != nil)
    }
}

// MARK: - ManualEntryFormViewDelegate

extension ManualEntryViewController: ManualEntryFormViewDelegate {
    
    func manualEntryFormViewTextDidChange(_ view: ManualEntryFormView) {
        adjustContinueButtonStateIfNeeded()
    }
}

// MARK: - Helpers
    
private func CreateContentView(
    headerView: UIView,
    formView: UIView
) -> (scrollView: UIScrollView, scrollViewContent: UIView) {
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            headerView,
            formView,
        ]
    )
    verticalStackView.axis = .vertical
    verticalStackView.isLayoutMarginsRelativeArrangement = true
    verticalStackView.spacing = 16
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

private func CreateHeaderView(title: String, subtitle: String) -> UIView {
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
    let labelStackView = UIStackView(
        arrangedSubviews: [
            titleLabel,
            subtitleLabel,
        ]
    )
    labelStackView.axis = .vertical
    labelStackView.spacing = 8
    return labelStackView
}
