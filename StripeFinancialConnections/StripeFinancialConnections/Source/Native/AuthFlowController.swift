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
    
    weak var delegate: AuthFlowControllerDelegate?

    private let dataManager: AuthFlowDataManager
    private let navigationController: FinancialConnectionsNavigationController
    private let api: FinancialConnectionsAPIClient
    private let clientSecret: String

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
    
    init(api: FinancialConnectionsAPIClient,
         clientSecret: String,
         dataManager: AuthFlowDataManager,
         navigationController: FinancialConnectionsNavigationController) {
        self.api = api
        self.clientSecret = clientSecret
        self.dataManager = dataManager
        self.navigationController = navigationController
        super.init()
        dataManager.delegate = self
    }
}

// MARK: - AuthFlowDataManagerDelegate

extension AuthFlowController: AuthFlowDataManagerDelegate {
    func authFlowDataManagerDidUpdateNextPane(_ dataManager: AuthFlowDataManager) {
        transitionToNextPane()
    }
    
    func authFlowDataManagerDidUpdateManifest(_ dataManager: AuthFlowDataManager) {
        // TODO(vardges): handle this
    }
    
    func authFlow(dataManager: AuthFlowDataManager, failedToUpdateManifest error: Error) {
        // TODO(vardges): handle this
    }
}

// MARK: - Public

extension AuthFlowController {
    
    func startFlow() {
        guard let next = self.nextPane() else {
            // TODO(vardges): handle this
            assertionFailure()
            return
        }

        navigationController.setViewControllers([next], animated: false)
    }
}

// MARK: - Helpers

private extension AuthFlowController {
    
    private func transitionToNextPane() {
        guard let next = self.nextPane() else {
            // TODO(vardges): handle this
            assertionFailure()
            return
        }
        navigationController.pushViewController(next, animated: true)
    }
    
    private func nextPane() -> UIViewController? {
        var viewController: UIViewController? = nil
        switch dataManager.nextPane() {
        case .accountPicker:
            fatalError("not been implemented")
        case .attachLinkedPaymentAccount:
            fatalError("not been implemented")
        case .consent:
            viewController = ConsentViewController(didConsent: { [weak self] in
                self?.dataManager.consentAcquired()
            })
        case .institutionPicker:
            let dataSource = InstitutionAPIDataSource(api: api, clientSecret: clientSecret)
            let picker = InstitutionPicker(dataSource: dataSource)
            picker.delegate = self
            viewController = picker
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
            let accountFetcher = FinancialConnectionsAccountAPIFetcher(api: api, clientSecret: clientSecret)
            let sessionFetcher = FinancialConnectionsSessionAPIFetcher(api: api, clientSecret: clientSecret, accountFetcher: accountFetcher)
            let webFlowController = FinancialConnectionsWebFlowViewController(clientSecret: clientSecret,
                                                                              apiClient: api,
                                                                              manifest: dataManager.manifest,
                                                                              sessionFetcher: sessionFetcher)
            webFlowController.delegate = self
            navigationController.dismissDelegate = webFlowController
            viewController = webFlowController
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
    
    private func displayAlert(_ message: String, viewController: UIViewController) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alertController.dismiss(animated: true)
        }
        alertController.addAction(OKAction)
        
        viewController.present(alertController, animated: true, completion: nil)
    }

    @objc
    func didTapClose() {
        delegate?.authFlow(controller: self, didFinish: result)
    }
}

// MARK: - FinancialConnectionsWebFlowViewControllerDelegate

extension AuthFlowController: FinancialConnectionsWebFlowViewControllerDelegate {
    func financialConnectionsWebFlow(viewController: FinancialConnectionsWebFlowViewController, didFinish result: FinancialConnectionsSheet.Result) {
        delegate?.authFlow(controller: self, didFinish: result)
    }
}

// MARK: - FinancialConnectionsNavigationControllerDelegate

extension AuthFlowController: FinancialConnectionsNavigationControllerDelegate {
    func financialConnectionsNavigationDidClose(_ navigationController: FinancialConnectionsNavigationController) {
        delegate?.authFlow(controller: self, didFinish: result)
    }
}

// MARK: - InstitutionPickerDelegate

extension AuthFlowController: InstitutionPickerDelegate {
    func institutionPicker(_ picker: InstitutionPicker, didSelect institution: FinancialConnectionsInstitution) {
        dataManager.picked(institution: institution)
    }
}
