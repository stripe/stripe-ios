//
//  AuthFlowController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/6/22.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol AuthFlowControllerDelegate: AnyObject {

    func authFlow(
        controller: AuthFlowController,
        didFinish result: FinancialConnectionsSheet.Result
    )
}

class AuthFlowController: NSObject {

    // MARK: - Properties
    
    let manifest: FinancialConnectionsSessionManifest
    weak var delegate: AuthFlowControllerDelegate?
    
    private var result: FinancialConnectionsSheet.Result = .canceled

    // MARK: - UI
    
    private lazy var closeItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: Image.close.makeImage(template: false),
                                   style: .plain,
                                   target: self,
                                   action: #selector(didTapClose))

        item.tintColor = UIColor.dynamic(light: CompatibleColor.systemGray2, dark: .white)
        return item
    }()

    // MARK: - Init
    
    init(manifest: FinancialConnectionsSessionManifest) {
        self.manifest = manifest
    }

}

// MARK: - Public

extension AuthFlowController {
    
    func nextPane() -> UIViewController? {
        var viewController: UIViewController? = nil
        switch manifest.nextPane {
        case .accountPicker:
            fatalError("not been implemented")
        case .attachLinkedPaymentAccount:
            fatalError("not been implemented")
        case .consent:
            viewController = UIViewController(nibName: nil, bundle: nil)
            viewController?.view.backgroundColor = .red
        case .institutionPicker:
            fatalError("not been implemented")
        case .linkConsent:
            fatalError("not been implemented")
        case .linkLogin:
            fatalError("not been implemented")
        case .manualEntry:
            fatalError("not been implemented")
        case .manualEntrySuccess:
            fatalError("not been implemented")
        case .networkingLinkSignupPane:
            fatalError("not been implemented")
        case .networkingLinkVerification:
            fatalError("not been implemented")
        case .partnerAuth:
            fatalError("not been implemented")
        case .success:
            fatalError("not been implemented")
        case .unexpectedError:
            fatalError("not been implemented")
        case .unparsable:
            fatalError("not been implemented")
        case .authOptions:
            fatalError("not been implemented")
        case .networkingLinkLoginWarmup:
            fatalError("not been implemented")
        }
        
        viewController?.navigationItem.rightBarButtonItem = closeItem
        return viewController
    }
}

// MARK: - Helpers

private extension AuthFlowController {

    @objc
    func didTapClose() {
        delegate?.authFlow(controller: self, didFinish: result)
    }
}

// MARK: - FinancialConnectionsNavigationControllerDelegate

extension AuthFlowController: FinancialConnectionsNavigationControllerDelegate {
    func financialConnectionsNavigationDidClose(_ navigationController: FinancialConnectionsNavigationController) {
        delegate?.authFlow(controller: self, didFinish: result)
    }
}
