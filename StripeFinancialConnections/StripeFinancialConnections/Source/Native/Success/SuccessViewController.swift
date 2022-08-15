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
        
        let scrollView = UIScrollView()
        
        let contentViewVerticalStack = UIStackView()
        contentViewVerticalStack.axis = .vertical
        contentViewVerticalStack.spacing = 24
        contentViewVerticalStack.isLayoutMarginsRelativeArrangement = true
        contentViewVerticalStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 24,
            bottom: 0, // footer has top-padding
            trailing: 24
        )
        
        let headerView = SuccessHeaderView(businessName: nil, isLinkingOneAccount: true)
        contentViewVerticalStack.addArrangedSubview(headerView)
        
        let bodyView = SuccessBodyView()
        contentViewVerticalStack.addArrangedSubview(bodyView)
        
        scrollView.addSubview(contentViewVerticalStack)
        
        let footerView = SuccessFooterView(
            didSelectDone: {
                print("done")
            },
            didSelectLinkAnotherAccount: {
                print("didSelectLinkAnotherAccount")
            }
        )
        
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                scrollView,
                footerView,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 0
        view.addAndPinSubviewToSafeArea(verticalStackView)
        
        // Align content view to the scroll view
        contentViewVerticalStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentViewVerticalStack.widthAnchor.constraint(equalTo: view.widthAnchor),
//            contentViewVerticalStack.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
//            contentViewVerticalStack.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            contentViewVerticalStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentViewVerticalStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
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

