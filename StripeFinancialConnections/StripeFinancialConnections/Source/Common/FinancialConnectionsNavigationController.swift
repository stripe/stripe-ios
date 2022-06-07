//
//  FinancialConnectionsNavigationController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/6/22.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore


protocol FinancialConnectionsNavigationControllerDelegate: AnyObject {
    func financialConnectionsNavigationDidClose(
        _ navigationController: FinancialConnectionsNavigationController
    )
}

class FinancialConnectionsNavigationController: UINavigationController {
    
    weak var dismissDelegate: FinancialConnectionsNavigationControllerDelegate?
    
    // MARK: - UIViewController
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isBeingDismissed {
            dismissDelegate?.financialConnectionsNavigationDidClose(self)
        }
    }
}
