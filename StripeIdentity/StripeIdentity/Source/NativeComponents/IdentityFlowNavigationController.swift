//
//  IdentityFlowNavigationController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/17/21.
//

import UIKit

protocol IdentityFlowNavigationControllerDelegate: AnyObject {
    /// Invoked when the user has dismissed the navigation controller
    func identityFlowNavigationControllerDidDismiss(_ navigationController: IdentityFlowNavigationController)
}

final class IdentityFlowNavigationController: UINavigationController {

    weak var identityDelegate: IdentityFlowNavigationControllerDelegate?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        identityDelegate?.identityFlowNavigationControllerDidDismiss(self)
    }
}
