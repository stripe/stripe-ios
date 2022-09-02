//
//  LinkMoreAccounts.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/2/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol LinkMoreAccountsViewControllerDelegate: AnyObject {
    func linkMoreAccountsViewController(
        _ viewController: LinkMoreAccountsViewController,
        didSucceedWithManifest manifest: FinancialConnectionsSessionManifest
    )
    func linkMoreAccountsViewController(
        _ viewController: LinkMoreAccountsViewController,
        didFailWithError error: Error
    )
}

final class LinkMoreAccountsViewController: UIViewController {
    
    private let dataSource: LinkMoreAccountsDataSource
    
    weak var delegate: LinkMoreAccountsViewControllerDelegate?
    
    init(dataSource: LinkMoreAccountsDataSource) {
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
        
        if #available(iOS 13.0, *) {
            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.stp_startAnimatingAndShow()
            view.addAndPinSubviewToSafeArea(activityIndicator)
        } else {
            assertionFailure()
        }
        
        dataSource.markLinkingMoreAccounts()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let manifest):
                    self.delegate?.linkMoreAccountsViewController(self, didSucceedWithManifest: manifest)
                case .failure(let error):
                    self.delegate?.linkMoreAccountsViewController(self, didFailWithError: error)
                }
            }
    }
}
