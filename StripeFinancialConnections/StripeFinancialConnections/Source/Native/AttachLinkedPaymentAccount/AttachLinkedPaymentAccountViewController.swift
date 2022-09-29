//
//  AttachLinkedPaymentAccountViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/28/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
protocol AttachLinkedPaymentAccountViewControllerDelegate: AnyObject {
    func attachLinkedPaymentAccountViewControlled(
        _ viewController: AttachLinkedPaymentAccountViewController,
        didFinishWithPaymentAccountResource paymentAccountResource: FinancialConnectionsPaymentAccountResource
    )
}

@available(iOSApplicationExtension, unavailable)
final class AttachLinkedPaymentAccountViewController: UIViewController {
    
    private let dataSource: AttachLinkedPaymentAccountDataSource
    weak var delegate: AttachLinkedPaymentAccountViewControllerDelegate?
    
    init(dataSource: AttachLinkedPaymentAccountDataSource) {
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
        
        let linkingAccountsLoadingView = LinkingAccountsLoadingView(
            numberOfSelectedAccounts: dataSource.selectedAccounts.count,
            businessName: dataSource.manifest.businessName
        )
        view.addAndPinSubviewToSafeArea(linkingAccountsLoadingView)
        
        dataSource.attachLinkedAccountIdToLinkAccountSession()
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let paymentAccountResource):
                    self.delegate?.attachLinkedPaymentAccountViewControlled(
                        self,
                        didFinishWithPaymentAccountResource: paymentAccountResource
                    )
                case .failure(let error):
                    print("^ got error", error)
                    break
                }
            }
    }
}
