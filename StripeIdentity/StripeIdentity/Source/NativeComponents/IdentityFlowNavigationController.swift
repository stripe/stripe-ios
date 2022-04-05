//
//  IdentityFlowNavigationController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/17/21.
//

import UIKit
@_spi(STP) import StripeUICore

/// View model used to customize the text on the alert shown
/// when asking a user to confirm whether they want to go back
struct WarningAlertViewModel {
    let titleText: String
    let messageText: String
    let acceptButtonText: String
    let declineButtonText: String
}

protocol IdentityFlowNavigationControllerDelegate: AnyObject {
    /// Invoked when the user has dismissed the navigation controller
    func identityFlowNavigationControllerDidDismiss(_ navigationController: IdentityFlowNavigationController)
}

final class IdentityFlowNavigationController: UINavigationController {

    weak var identityDelegate: IdentityFlowNavigationControllerDelegate?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)

        // Only full screen presentation style disables landscape
        self.modalPresentationStyle = .fullScreen
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBorderlessNavigationBar()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        identityDelegate?.identityFlowNavigationControllerDidDismiss(self)
    }
}

// MARK: - IdentityFlowNavigationController Helpers

private extension IdentityFlowNavigationController {
    func configureAndPresentWarningAlert(with viewModel: WarningAlertViewModel) {
        let alertController = UIAlertController(
            title: viewModel.titleText,
            message: viewModel.messageText,
            preferredStyle: .alert
        )

        alertController.addAction(.init(
            title: viewModel.acceptButtonText,
            style: .cancel,
            handler: { [weak self] _ in
                self?.popViewController(animated: true)
            }
        ))

        alertController.addAction(.init(
            title: viewModel.declineButtonText,
            style: .default,
            handler: nil
        ))

        present(alertController, animated: true, completion: nil)
     }
}

// MARK: - IdentityFlowNavigationController: UINavigationBarDelegate Delegate

@available(iOSApplicationExtension, unavailable)
extension IdentityFlowNavigationController: UINavigationBarDelegate {
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        guard
            let vc = self.viewControllers.last(where: { $0.navigationItem === item}) as? IdentityFlowViewController,
            let warningAlertViewModel = vc.warningAlertViewModel
        else {
            return true
        }

        configureAndPresentWarningAlert(with: warningAlertViewModel)
        return false
    }
}
