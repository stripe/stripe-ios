//
//  SuccessViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/12/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
protocol SuccessViewControllerDelegate: AnyObject {
    func successViewControllerDidSelectLinkMoreAccounts(_ viewController: SuccessViewController)
    func successViewController(
        _ viewController: SuccessViewController,
        didCompleteSession session: StripeAPI.FinancialConnectionsSession
    )
}

@available(iOSApplicationExtension, unavailable)
final class SuccessViewController: UIViewController {
    
    private let dataSource: SuccessDataSource
    weak var delegate: SuccessViewControllerDelegate?
    
    init(dataSource: SuccessDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor
        navigationItem.hidesBackButton = true
        
        let contentViewPair = CreateContentView(
            manifest: dataSource.manifest,
            institution: dataSource.institution,
            linkedAccounts: dataSource.linkedAccounts
        )
        let contentScrollView = contentViewPair.contentScrollView
        let scrollViewContentView = contentViewPair.contentView
        
        let footerView = SuccessFooterView(
            didSelectDone: { [weak self] in
                self?.didSelectDone()
            },
            didSelectLinkAnotherAccount: dataSource.showLinkMoreAccountsButton ? { [weak self] in
                guard let self = self else { return }
                self.delegate?.successViewControllerDidSelectLinkMoreAccounts(self)
            } : nil
        )
        
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                contentScrollView,
                footerView,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 0
        view.addAndPinSubviewToSafeArea(verticalStackView)
        
        // Align content view to the scroll view
        scrollViewContentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollViewContentView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            scrollViewContentView.topAnchor.constraint(equalTo: contentScrollView.topAnchor),
            scrollViewContentView.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),
        ])
    }
    
    private func didSelectDone() {
        dataSource.completeFinancialConnectionsSession()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let session):
                    self.delegate?.successViewController(self, didCompleteSession: session)
                case .failure(let error):
                    print(error) // TODO(kgaidis): handle error properly
                }
            }
    }
}

@available(iOSApplicationExtension, unavailable)
private func CreateContentView(
    manifest: FinancialConnectionsSessionManifest,
    institution: FinancialConnectionsInstitution,
    linkedAccounts: [FinancialConnectionsPartnerAccount]
) -> (contentScrollView: UIScrollView, contentView: UIView) {
    
    let scrollContentViewVerticalStack = UIStackView(
        arrangedSubviews: [
            SuccessHeaderView(
                businessName: manifest.businessName,
                isLinkingOneAccount: (linkedAccounts.count <= 1)
            ),
            SuccessBodyView(
                institution: institution,
                linkedAccounts: linkedAccounts,
                manifest: manifest
            )
        ]
    )
    scrollContentViewVerticalStack.axis = .vertical
    scrollContentViewVerticalStack.spacing = 24
    scrollContentViewVerticalStack.isLayoutMarginsRelativeArrangement = true
    scrollContentViewVerticalStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 8,
        leading: 24,
        bottom: 0, // footer has top-padding
        trailing: 24
    )
    
    let scrollView = UIScrollView()
    scrollView.addSubview(scrollContentViewVerticalStack)
    
    return (scrollView, scrollContentViewVerticalStack)
}
